function trf_binds(binds::Dict)
new_binds=Dict{String,Any}()
    for (k,v) in binds

        (path_src,attr_src)=try 
                arr_s=split(k,".")
               (string(join(arr_s[1:end-1],".")),string(arr_s[end]))
            catch
                ("","")
            end

         (path_tgt,attr_tgt)=try 
                arr_s=split(v,".")

            (string(join(arr_s[1:end-1],".")),string(arr_s[end]))
            catch
                ("","")
            end

        if haskey(new_binds,path_src)
            if haskey(new_binds[path_src],attr_src)
                new_binds[path_src][attr_src][path_tgt]=attr_tgt
            else
                new_binds[path_src][attr_src]=Dict(path_tgt=>attr_tgt)
            end
        else
            new_binds[path_src]=Dict(attr_src=>Dict(path_tgt=>attr_tgt))
        end

    end

    return new_binds
end

function reverse_binds(binds::Dict)
 reverse_d=Dict{String,Any}()
    
    for (k,v) in binds
        
        for (kk,vv) in v
          values=Dict(k=>kk)
                    
            for (kkk,vvv) in vv
                if haskey(reverse_d,kkk)
                     reverse_d[kkk][vvv]=values
                else
                    reverse_d[kkk]=Dict(vvv=>values)
                end
                
            end

        end
    end
    return reverse_d
end

element_binds!(comp::String;binds=Dict())=nothing
element_binds!(comp::VueJS.VueComponent;binds=Dict())=element_binds!(comp.grid,binds=binds)

element_binds!(el::Array;binds=Dict())=map(x->element_binds!(x,binds=binds),el)

function element_binds!(el::VueJS.VueElement;binds=Dict()) 
    
    full_path=el.path=="" ? el.id : el.path*"."*el.id
    
    ## update binds in element due to be binded to other element
    if haskey(binds,full_path)
        for (k,v) in binds[full_path]
                el.binds[k]=collect(keys(v))[1]*"."*collect(values(v))[1]
        end
    end
           
    reverse_b=VueJS.reverse_binds(binds)
    ## update binds in element due to be binded in other element
    if haskey(reverse_b,full_path)
        for (k,v) in reverse_b[full_path]
            el.binds[k]=el.id*"."*k
        end
    end

    
end
