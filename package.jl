using PkgTemplates

t = Template(;
    user="franklynwang",
    dir="~/Dropbox/Ecne_fixed",
    julia=v"1.6",
    plugins=[
        Git(; manifest=true, ssh=true),
        GitHubActions(; x86=true),
        Codecov(),
        Documenter{GitHubActions}(),
    ]
)

t("R1CSConstraintSolver.jl")