using Documenter, DocumenterMarkdown
using Literate

get_example_path(p) = joinpath(@__DIR__, ".", "crash", p)
OUTPUT = joinpath(@__DIR__, "src", "crash", "generated")

folders = readdir(joinpath(@__DIR__, ".", "crash"))
setdiff!(folders, [".DS_Store"])

function getfiles()
    srcsfiles = []
    for f in folders
        names = readdir(joinpath(@__DIR__, ".", "crash", f))
        setdiff!(names, [".DS_Store"])
        fpaths  = "$(f)/" .* names
        srcsfiles = vcat(srcsfiles, fpaths...)
    end
    return srcsfiles
end

srcsfiles = getfiles()

for (d, paths) in (("tutorial", srcsfiles),)
    for p in paths
    Literate.markdown(get_example_path(p), joinpath(OUTPUT, dirname(p));
            documenter=true)
    end
end