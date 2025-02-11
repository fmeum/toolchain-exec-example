LangToolchainInfo = provider(fields = ["target_dep", "exec_dep", "indirect_exec_dep"])

def _lang_toolchain_impl(ctx):
    target_dep = ctx.file.target_dep
    exec_dep = ctx.file.exec_dep
    indirect_exec_dep = ctx.file.indirect_exec_dep

    return [
        platform_common.ToolchainInfo(
            lang_toolchain = LangToolchainInfo(
                target_dep = target_dep,
                exec_dep = exec_dep,
                indirect_exec_dep = indirect_exec_dep,
            ),
        ),
    ]

lang_toolchain = rule(
    implementation = _lang_toolchain_impl,
    attrs = {
        "target_dep": attr.label(
            cfg = "target",
            executable = True,
            allow_single_file = True,
            default = "//tool",
        ),
        "exec_dep": attr.label(
            cfg = "exec",
            executable = True,
            allow_single_file = True,
            default = "//tool",
        ),
        "indirect_exec_dep": attr.label(
            cfg = "target",
            executable = True,
            allow_single_file = True,
            default = "//toolchain:indirect_tool",
        ),
    },
)

def _consuming_rule_impl(ctx):
    default_toolchain = ctx.toolchains["//toolchain:toolchain_type"].lang_toolchain
    default_out = ctx.actions.declare_file(ctx.label.name + "_default.out")
    ctx.actions.run_shell(
        inputs = depset([
            default_toolchain.target_dep,
            default_toolchain.exec_dep,
            default_toolchain.indirect_exec_dep,
        ]),
        outputs = [default_out],
        toolchain = "//toolchain:toolchain_type",
        command = """
echo "target_dep:" > $1
$2 >> $1
echo "exec_dep:" >> $1
$3 >> $1
echo "indirect_exec_dep:" >> $1
$4 >> $1
""",
        arguments = [
            default_out.path,
            default_toolchain.target_dep.path,
            default_toolchain.exec_dep.path,
            default_toolchain.indirect_exec_dep.path,
        ],
    )

    custom_toolchain = ctx.exec_groups["custom"].toolchains["//toolchain:toolchain_type"].lang_toolchain
    custom_out = ctx.actions.declare_file(ctx.label.name + "_custom.out")
    ctx.actions.run_shell(
        inputs = depset([
            custom_toolchain.target_dep,
            custom_toolchain.exec_dep,
            custom_toolchain.indirect_exec_dep,
        ]),
        outputs = [custom_out],
        exec_group = "custom",
        command = """
echo "target_dep:" > $1
$2 >> $1
echo "exec_dep:" >> $1
$3 >> $1
echo "indirect_exec_dep:" >> $1
$4 >> $1
""",
        arguments = [
            custom_out.path,
            custom_toolchain.target_dep.path,
            custom_toolchain.exec_dep.path,
            custom_toolchain.indirect_exec_dep.path,
        ],
    )

    return DefaultInfo(
        files = depset([default_out, custom_out]),
    )

consuming_rule = rule(
    implementation = _consuming_rule_impl,
    toolchains = [
        "//toolchain:toolchain_type",
    ],
    exec_groups = {
        "custom": exec_group(
            toolchains = [
                "//toolchain:toolchain_type",
            ],
            exec_compatible_with = [
                "@platforms//os:windows",
                "@platforms//cpu:arm64",
            ],
        ),
    },
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
)
