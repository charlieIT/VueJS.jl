function htmlstring(page_inst::Page)
    includes=[]
    css_deps=[]
    for d in page_inst.dependencies
        if d.type == "js"
            push!(includes, head("script"=>Dict("src"=>d.path)))
        elseif d.type == "css"
            push!(includes, head("link"=>Dict("rel"=>"stylesheet", "type"=>"text/css", "href"=>d.path)))
        end
        push!(css_deps, d.css)
    end

    head_dom = deepcopy(HEAD)
    if page_inst.title !== nothing push!(head_dom.value, head("title"=>page_inst.title)) end
    
    [push!(head_dom.value, meta) for meta in page_inst.meta]
    
    append!(head_dom.value, includes)   
    
    push!(head_dom.value, html("style",join(css_deps," ")))
        
    scripts=deepcopy(page_inst.scripts)
        
    push!(scripts,"const vuetify = new Vuetify()")
    components = Dict{String,String}()
    [merge!(components, d.components) for d in page_inst.dependencies if length(d.components) > 0]
    
    push!(scripts,"""const components = $(replace(JSON.json(components),"\""=>""))""")
    
    components_dom=[]
    app_state=Dict{String,Any}()
    ## initialize globals
    app_state["globals"]=page_inst.globals

    ## Other components
    for (k,v) in page_inst.components
        if k=="v-main"
            ## component script
            update_data!(v,v.data)
            update_events!(v)
            merge!(app_state,v.def_data)
            
            comp_script=[]
            push!(comp_script,"el: '#app'")
            push!(comp_script,"vuetify: vuetify")
            push!(comp_script,"components:components")
            push!(comp_script,"data: app_state")
            push!(comp_script, v.scripts)
            
            comp_script="var app = new Vue({"*join(comp_script,",")*"})"
            push!(scripts,comp_script)    
            opts=PAGE_OPTIONS
            opts.path="root"
            push!(components_dom,html("v-main",html("v-container",dom(v,opts=opts),Dict("fluid"=>true)),Dict()))
        else
            
            opts=PAGE_OPTIONS
            if v isa VueHolder
                vsid=vue_escape(k)
                vs=VueStruct("",[VueStruct(vsid,[v])])
                opts.path=vsid
            else
                vs=VueStruct(vue_escape(k),[v])
                opts.path=""
            end
            
            update_data!(vs,vs.data)
            update_events!(vs)
            merge!(app_state,vs.def_data)
            
            comp_el=VueJS.dom([vs],opts=opts)[1].value.value            
            comp_el.attrs["app"]=true
            push!(components_dom,comp_el)
        end
    end
    
    scripts=vcat("const app_state = $(vue_json(app_state))",scripts)
            
    body_dom=html("body",[html("div",html("v-app",components_dom),Dict("id"=>"app","v-cloak"=>true))],Dict())
        
    htmlpage=html("html",[head_dom,body_dom],Dict())
    
    return join([htmlstring(htmlpage), """<script>xhr=$(xhr_script)\n $(join(scripts,"\n"))</script>"""])
end
