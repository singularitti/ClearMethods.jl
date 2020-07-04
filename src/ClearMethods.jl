module ClearMethods

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

function Base.show(io::IO, m::Method)
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
    Base.show_method_params(io, tv)
    println(io)
    printstyled(io, " " * "@ ", color = :light_black)
    # if !isempty(m.module)
    #     printstyled(io, m.module, color = :yellow)
    #     print(io, " ")
    # end
    printstyled(io, m.module, color = :yellow)
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

end
