# KCL rules for Bazel

These are build rules for KCL tools during a Bazel build.

## How to Use

Write a `BUILD.bazel` file and run the following command

```bazel
load("@org_kcl_lang_rules_kcl//kcl:defs.bzl", "kcl_run")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file")

kcl_run(
    name = "hello.yaml.write",
    files = ["main.k"],
    format = "yaml",
)

write_source_file(
    name = "hello.yaml.update",
    in_file = ":hello.yaml.write",
    out_file = "hello.yaml",
    suggested_update_target = "//:hello.yaml.update",
)
```

```shell
bazel build //:hello.yaml.update --action_env=HOME=~
```

## Build Rules

### kcl_run

```starlark
kcl_run(files, codes=[], deps=[], args=[], overrides=[], selectors=[], settings=[], format="yaml", output="", disable_none=False, debug=False, sort_keys=False, vendor=False, strict_range_check=False, no_style=False)
```

Run KCL files and output the JSON/YAML result.

| Attribute            | Description                                                                              |
| -------------------- | ---------------------------------------------------------------------------------------- |
| `files`              | KCL files (required)                                                                     |
| `codes`              | KCL Codes (optional)                                                                     |
| `deps`               | List of the dep external packages  (optional)                                            |
| `args`               | List of the top-level arguments  (optional)                                              |
| `overrides`          | List of the configuration override path and values  (optional)                           |
| `selectors`          | List of the path selectors  (optional)                                                   |
| `settings`           | List of the command line setting files  (optional)                                       |
| `format`             | Export format, must be one of `"json", "yaml"`                                           |
| `output`             | Output file name (required, default is "" that presents stdout)                          |
| `disable_none`       | Disable dumping None values (optional)                                                   |
| `debug`              | Run in debug mode (optional)                                                             |
| `sort_keys`          | Sort output result keys (optional)                                                       |
| `vendor`             | Run in vendor mode (optional)                                                            |
| `strict_range_check` | Do perform strict numeric range checks (optional)                                        |
| `no_style`           | Set to prohibit output of command line waiting styles, including colors, etc. (optional) |

Run `kcl run --help` to get more information.

## Developing

+ Install [Bazel](https://bazel.build/)
+ Build all Bazel targets

```shell
bazel build //... --action_env=HOME=~
```

+ Testing

```shell
bazel test --test_output=errors //...
```

+ Formatting

```shell
go install github.com/bazelbuild/buildtools/buildifier@latest
buildifier -r .
```

## Roadmap

+ [ ] KCL module related commands, e.g. `kcl mod add k8s`
