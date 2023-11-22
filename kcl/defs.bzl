"""
To load these rules, add this to the top of your `BUILD` file:

```starlark
load("@rules_kcl//kcl:defs.bzl", ...)
```
"""

def _collect_runfiles(ctx, direct_files, indirect_targets):
    """Builds a runfiles object for the current target.

    Source:
      https://github.com/jayconrod/rules_go_simple/blob/43b692d481140486513b00f862fbde9938f90a77/internal/rules.bzl#L323

    Args:
        ctx: analysis context.
        direct_files: list of Files to include directly.
        indirect_targets: list of Targets to gather transitive runfiles from.
    Returns:
        A runfiles object containing direct_files and runfiles from
        indirect_targets. The files from indirect_targets won't be included
        unless they are also included in runfiles.
    """
    return ctx.runfiles(
        files = direct_files,
        # Note that we are using `data_runfiles` rather than `default_runfiles`.
        # Even though, this is in contrary with the bazel third recomendation from [1],
        # `filegroup` rule does NOT respect the fact that `srcs` should be added also
        # to the `default_runfiles`.
        # [1] https://bazel.build/extending/rules#runfiles_features_to_avoid
        transitive_files = depset(
            transitive = [target[DefaultInfo].data_runfiles.files for target in indirect_targets],
        ),
    )

def _kcl_run_impl(ctx):
    kcl = ctx.toolchains["//kcl:toolchain_type"].kcl_info

    args = ctx.actions.args()
    args.add_all(["run"])
    args.add_all(ctx.files.files)
    args.add_all([
        "--format",
        ctx.attr.format,
    ])
    output = ctx.actions.declare_file(ctx.label.name)
    args.add_all(["--output", output.path])
    for v in ctx.attr.deps:
        args.add_all([
            "-E",
            v,
        ])
    for v in ctx.attr.args:
        args.add_all([
            "-D",
            v,
        ])
    for v in ctx.attr.overrides:
        args.add_all([
            "-O",
            v,
        ])
    for v in ctx.attr.selectors:
        args.add_all([
            "-S",
            v,
        ])
    for v in ctx.attr.settings:
        args.add_all([
            "-Y",
            v,
        ])

    if ctx.attr.disable_none:
        args.add_all(["--disable_none"])
    if ctx.attr.debug:
        args.add_all(["--debug"])
    if ctx.attr.sort_keys:
        args.add_all(["--sort_keys"])
    if ctx.attr.vendor:
        args.add_all(["--vendor"])
    if ctx.attr.strict_range_check:
        args.add_all(["--strict_range_check"])
    if ctx.attr.no_style:
        args.add_all(["--no_style"])

    runfiles = _collect_runfiles(
        ctx,
        direct_files = ctx.files.files,
        indirect_targets = [],
    )

    ctx.actions.run(
        inputs = runfiles.files,
        arguments = [args],
        executable = kcl.binary,
        toolchain = "//kcl:toolchain_type",
        outputs = [output],
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(
            files = depset([output]),
        ),
    ]

_kcl_run_attrs = {
    "files": attr.label_list(
        doc = "Input KCL filenames",
        allow_files = [".k"],
    ),
    "codes": attr.string_list(
        doc = "Input KCL codes",
    ),
    "deps": attr.string_list(
        doc = "List of the dep external packages",
        default = [],
    ),
    "args": attr.string_list(
        doc = "List of the top-level arguments",
        default = [],
    ),
    "overrides": attr.string_list(
        doc = "List of the configuration override path and values",
        default = [],
    ),
    "selectors": attr.string_list(
        doc = "List of the path selectors",
        default = [],
    ),
    "settings": attr.string_list(
        doc = "List of the command line setting files",
        default = [],
    ),
    "format": attr.string(
        doc = "Export format, must be one of json, yaml",
        default = "yaml",
        values = [
            "json",
            "yaml",
        ],
    ),
    "output": attr.string(
        doc = "Output file name (required, default is '' that presents stdout)",
        default = "",
    ),
    "disable_none": attr.bool(
        doc = "Disable dumping None values",
        default = False,
    ),
    "debug": attr.bool(
        doc = "Run in debug mode",
        default = False,
    ),
    "sort_keys": attr.bool(
        doc = "Sort output result keys",
        default = False,
    ),
    "vendor": attr.bool(
        doc = "Run in vendor mode (optional)",
        default = False,
    ),
    "strict_range_check": attr.bool(
        doc = "Do perform strict numeric range checks",
        default = False,
    ),
    "no_style": attr.bool(
        doc = "Set to prohibit output of command line waiting styles, including colors, etc. (optional)",
        default = False,
    ),
}

kcl_run = rule(
    implementation = _kcl_run_impl,
    attrs = _kcl_run_attrs,
    toolchains = ["//kcl:toolchain_type"],
)
