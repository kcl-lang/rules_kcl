"""This module implements the language-specific toolchain rule.
"""

KCLInfo = provider(
    doc = "Information about how to invoke the tool executable.",
    fields = {
        "binary": "Path to the KCL binary.",
    },
)

def _kcl_toolchain_impl(ctx):
    binary = ctx.executable.kcl

    # Make the $(tool_BIN) variable available in places like genrules.
    # See https://docs.bazel.build/versions/main/be/make-variables.html#custom_variables
    template_variables = platform_common.TemplateVariableInfo({
        "KCL_BIN": binary.path,
    })

    default = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    kcl_info = KCLInfo(
        binary = binary,
    )

    # Export all the providers inside our ToolchainInfo
    # so the resolved_toolchain rule can grab and re-export them.
    toolchain_info = platform_common.ToolchainInfo(
        kcl_info = kcl_info,
        template_variables = template_variables,
        default = default,
    )
    return [
        default,
        toolchain_info,
        template_variables,
    ]

kcl_toolchain = rule(
    implementation = _kcl_toolchain_impl,
    attrs = {
        "kcl": attr.label(
            doc = "A hermetically downloaded executable target for the build platform.",
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    doc = """Defines a KCL toolchain.

For usage see https://docs.bazel.build/versions/main/toolchains.html#defining-toolchains.
""",
)
