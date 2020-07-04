module ClearMethods

const MODULECOLORS = [:light_blue, :light_yellow, :light_red, :light_green, :light_magenta, :light_cyan, :blue, :yellow, :red, :green, :magenta, :cyan]
const EXPAND_BASE_PATHS = Ref(true)
const CONTRACT_USER_DIR = Ref(true)

function getfile(file)
    if EXPAND_BASE_PATHS[]
        file = expandbasepath(file)
    end
    if CONTRACT_USER_DIR[]
        file = replaceuserpath(file)
    end
    return file
end

function expandbasepath(str)
    basefileregex = if Sys.iswindows()
        r"^\.\\\w+\.jl$"
    else
        r"^\./\w+\.jl$"
    end
    if !isnothing(match(basefileregex, str))
        sourcestring = Base.find_source_file(str[3:end]) # cut off ./
    else
        str
    end
end

function replaceuserpath(str)
    str1 = replace(str, homedir() => "~")
    # seems to be necessary for some paths with small letter drive c:// etc
    replace(str1, lowercasefirst(homedir()) => "~")
end

function Base.show(io::IO, m::Method, modulecolor = :yellow)
    tv, decls, file, line = Base.arg_decl_parts(m)
    sig = Base.unwrap_unionall(m.sig)
    if sig === Tuple
        # Builtin
        print(io, m.name, "(...) in ", m.module)
        return
    end
    printstyled(io, m.name; bold = true)
    if !isempty(decls[2:end])
        # type signature
        printstyled(io, "(", color = :light_black)

        for (i, (varname, vartype)) in enumerate(decls[2:end])
            if i > 1
                printstyled(io, ", ", color = :light_black)
            end
            printstyled(io, string(varname), color = :light_black, bold = true)
            if !isempty(vartype)
                printstyled(io, "::")
                printstyled(io, string(vartype), color = :light_black)
            end
        end
    end
    kwargs = Base.kwarg_decl(m)
    if !isempty(kwargs)
        print(io, "; ")
        for k in kwargs
            printstyled(io, string(k), color = :light_black, bold = true)
            print(io, ", ")
        end
    end
    printstyled(io, ")", color = :light_black)
    show_method_params(io, tv)
    println(io)
    printstyled(io, " " * "@ ", color = :light_black)
    # if !isempty(m.module)
    #     printstyled(io, m.module, color = :yellow)
    #     print(io, " ")
    # end
    printstyled(io, m.module, color = modulecolor)
    print(io, " ")
    if line > 0
        file, line = Base.updated_methodloc(m)
        file = getfile(file)
    end

    pathparts = splitpath(file)
    folderparts = pathparts[1:end-1]
    if !isempty(folderparts)
        printstyled(io, joinpath(folderparts...) * (Sys.iswindows() ? "\\" : "/"), color = :light_black)
    end

    # filename, separator, line
    # bright black (90) and underlined (4)
    print(io, "\033[90;4m$(pathparts[end] * ":" * string(line))\033[0m")
end

function show_method_params(io::IO, tv)
    if !isempty(tv)
        printstyled(io, " where "; color = :light_black)
        if length(tv) == 1
            printstyled(io, tv[1]; color = :light_black)
        else
            printstyled(io, "{"; color = :light_black)
            for i = 1:length(tv)
                if i > 1
                    printstyled(io, ", "; color = :light_black)
                end
                x = tv[i]
                printstyled(io, x; color = :light_black)
                io = IOContext(io, :unionall_env => x)
            end
            printstyled(io, "}"; color = :light_black)
        end
    end
end # function show_method_params

getmodule(m::Method) = m.module
getmodule(list::Base.MethodList) = map(getmodule, list)

function Base.show_method_table(io::IO, ms::Base.MethodList, max::Int=-1, header::Bool=true)
    mt = ms.mt
    name = mt.name
    hasname = isdefined(mt.module, name) &&
              typeof(getfield(mt.module, name)) <: Function
    if header
        Base.show_method_list_header(io, ms, str -> "\""*str*"\"")
    end
    n = rest = 0
    local last
    LAST_SHOWN_LINE_INFOS = get(io, :LAST_SHOWN_LINE_INFOS, Tuple{String,Int}[])

    modules = getmodule(ms)

    uniquemodules = setdiff(unique(modules), [""])
    modulecolors = Dict(u => c for (u, c) in
        Iterators.zip(uniquemodules, Iterators.cycle(MODULECOLORS)))

    resize!(LAST_SHOWN_LINE_INFOS, 0)
    for meth in ms
        if max==-1 || n<max
            n += 1
            println(io)
            print(io, "[$n] ")
            modulecolor = get(modulecolors, meth.module, :default)
            show(io, meth, modulecolor)
            file, line = Base.updated_methodloc(meth)
            push!(LAST_SHOWN_LINE_INFOS, (string(file), line))
        else
            rest += 1
            last = meth
        end
    end
    if rest > 0
        println(io)
        if rest == 1
            show(io, last)
        else
            print(io, "... $rest methods not shown")
            if hasname
                print(io, " (use methods($name) to see them all)")
            end
        end
    end
end

end
