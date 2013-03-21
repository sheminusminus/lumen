current_target="js";current_language="lua";function eval(x)local f=loadstring(x);return(f()); end function array_length(arr)if (arr[0]==nil) then return(0); else return((#arr+1)); end  end function array_sub(arr,from,upto)do upto=(upto or array_length(arr));local i=from;local j=0;local arr2={};while (i<upto) do arr2[j]=arr[i];i=(i+1);j=(j+1); end return(arr2); end  end function array_push(arr,x)arr[array_length(arr)]=x; end function string_length(str)return(string.len(str)); end function string_start()return(1); end function string_end(str)return(string_length(str)); end function string_ref(str,n)return(string.sub(str,n,n)); end function string_sub(str,from,upto)do if (not (upto==nil)) then upto=(upto-1); end return(string.sub(str,from,upto)); end  end function string_find(str,pattern,start)return(string.find(str,pattern,(start or 1),true)); end function read_file(filename)do local f=io.open(filename);return(f:read("*a")); end  end function write_file(filename,data)do local f=io.open(filename,"w");f:write(data); end  end function exit(code)os.exit(code); end function parse_number(str)return(tonumber(str)); end function to_string(x)if (x==nil) then return("nil"); elseif ((type(x)=="string") or (type(x)=="number")) then return((x.."")); else local str="[";local i=0;while (i<array_length(x)) do local y=x[i];str=(str..to_string(y));if (i<(array_length(x)-1)) then str=(str.." "); end i=(i+1); end return((str.."]")); end  end delimiters={};delimiters["("]=true;delimiters[")"]=true;delimiters[";"]=true;delimiters["\n"]=true;whitespace={};whitespace[" "]=true;whitespace["\t"]=true;whitespace["\n"]=true;eof={};function make_stream(str)local s={};s.pos=string_start();s.string=str;s.last=string_end(str);return(s); end function peek_char(s)return((((s.pos<=s.last) and string_ref(s.string,s.pos)) or eof)); end function read_char(s)local c=peek_char(s);if c then s.pos=(s.pos+1);return(c); end  end function skip_non_code(s)local c;while true do c=peek_char(s);if (not c) then break; elseif whitespace[c] then read_char(s); elseif (c==";") then while (c and (not (c=="\n"))) do c=read_char(s); end skip_non_code(s); else break; end  end  end function read_atom(s)local c;local str="";while true do c=peek_char(s);if (c and ((not whitespace[c]) and (not delimiters[c]))) then str=(str..c);read_char(s); else break; end  end local n=parse_number(str);return((((n==nil) and str) or n)); end function read_list(s)read_char(s);local c;local l={};while true do skip_non_code(s);c=peek_char(s);if (c and (not (c==")"))) then array_push(l,read(s)); elseif c then read_char(s);break; else error(("Expected ) at "..s.pos)); end  end return(l); end function read_string(s)read_char(s);local c;local str="\"";while true do c=peek_char(s);if (c and (not (c=="\""))) then if (c=="\\") then str=(str..read_char(s)); end str=(str..read_char(s)); elseif c then read_char(s);break; else error(("Expected \" at "..s.pos)); end  end return((str.."\"")); end function read_quote(s)read_char(s);return({[0]="quote",read(s)}); end function read_unquote(s)read_char(s);return({[0]="unquote",read(s)}); end function read(s)skip_non_code(s);local c=peek_char(s);if (c==eof) then return(c); elseif (c=="(") then return(read_list(s)); elseif (c==")") then error(("Unexpected ) at "..s.pos)); elseif (c=="\"") then return(read_string(s)); elseif (c=="'") then return(read_quote(s)); elseif (c==",") then return(read_unquote(s)); else return(read_atom(s)); end  end operators={};function define_operators()operators["+"]="+";operators["-"]="-";operators["<"]="<";operators[">"]=">";operators["<="]="<=";operators[">="]=">=";operators["="]="==";operators["and"]=(((current_target=="js") and "&&") or " and ");operators["or"]=(((current_target=="js") and "||") or " or ");operators["cat"]=(((current_target=="js") and "+") or ".."); end special={};function define_special()special["do"]=compile_do;special["set"]=compile_set;special["get"]=compile_get;special["dot"]=compile_dot;special["not"]=compile_not;special["if"]=compile_if;special["function"]=compile_function;special["local"]=compile_local;special["while"]=compile_while;special["list"]=compile_list;special["quote"]=compile_quote; end macros={};function is_atom(form)return(((type(form)=="string") or (type(form)=="number"))); end function is_call(form)return((type(form[0])=="string")); end function is_operator(form)return((not (operators[form[0]]==nil))); end function is_special(form)return((not (special[form[0]]==nil))); end function is_macro_call(form)return((not (macros[form[0]]==nil))); end function is_macro_definition(form)return((form[0]=="macro")); end function terminator(is_stmt)return(((is_stmt and ";") or "")); end function compile_args(forms)local i=0;local str="(";while (i<array_length(forms)) do str=(str..compile(forms[i],false));if (i<(array_length(forms)-1)) then str=(str..","); end i=(i+1); end return((str..")")); end function compile_body(forms)local i=0;local str=(((current_target=="js") and "{") or "");while (i<array_length(forms)) do str=(str..compile(forms[i],true));i=(i+1); end return((((current_target=="js") and (str.."}")) or str)); end function compile_atom(form,is_stmt)if (form=="[]") then return((((current_target=="lua") and "{}") or "[]")); elseif (form=="nil") then return((((current_target=="js") and "undefined") or "nil")); elseif ((type(form)=="string") and (not (string_ref(form,string_start())=="\""))) then local atom="";local i=string_start();while (i<=string_end(form)) do local c=string_ref(form,i);if (c=="-") then c="_"; end atom=(atom..c);i=(i+1); end local last=string_end(form);if (string_ref(form,last)=="?") then local name=string_sub(atom,string_start(),last);atom=("is_"..name); end return((atom..terminator(is_stmt))); else return(form); end  end function compile_call(form,is_stmt)local fn=compile(form[0],false);local args=compile_args(array_sub(form,1));return((fn..args..terminator(is_stmt))); end function compile_operator(form)local i=1;local str="(";local op=operators[form[0]];while (i<array_length(form)) do str=(str..compile(form[i],false));if (i<(array_length(form)-1)) then str=(str..op); end i=(i+1); end return((str..")")); end function compile_do(forms,is_stmt)if (not is_stmt) then error("Cannot compile DO as an expression"); end local body=compile_body(forms);return((((current_target=="js") and body) or ("do "..body.." end "))); end function compile_set(form,is_stmt)if (not is_stmt) then error("Cannot compile assignment as an expression"); end if (array_length(form)<2) then error("Missing right-hand side in assignment"); end local lh=compile(form[0],false);local rh=compile(form[1],false);return((lh.."="..rh..terminator(true))); end function compile_branch(branch,is_first,is_last)local condition=compile(branch[0],false);local body=compile_body(array_sub(branch,1));local tr="";if (is_last and (current_target=="lua")) then tr=" end "; end if is_first then return((((current_target=="js") and ("if("..condition..")"..body)) or ("if "..condition.." then "..body..tr))); elseif (is_last and (condition=="true")) then return((((current_target=="js") and ("else"..body)) or (" else "..body.." end "))); else return((((current_target=="js") and ("else if("..condition..")"..body)) or (" elseif "..condition.." then "..body..tr))); end  end function compile_if(form,is_stmt)if (not is_stmt) then error("Cannot compile IF as an expression"); end local i=0;local str="";while (i<array_length(form)) do local is_last=(i==(array_length(form)-1));local is_first=(i==0);local branch=compile_branch(form[i],is_first,is_last);str=(str..branch);i=(i+1); end return(str); end function compile_function(form,is_stmt)local name=compile(form[0]);local args=compile_args(form[1]);local body=compile_body(array_sub(form,2));local tr=(((current_target=="lua") and " end ") or "");return(("function "..name..args..body..tr)); end function compile_get(form,is_stmt)local object=compile(form[0],false);local key=compile(form[1],false);return((object.."["..key.."]"..terminator(is_stmt))); end function compile_dot(form,is_stmt)local object=compile(form[0],false);local key=form[1];return((object.."."..key..terminator(is_stmt))); end function compile_not(form,is_stmt)local expr=compile(form[0],false);local tr=terminator(is_stmt);return((((current_target=="js") and ("!("..expr..")"..tr)) or ("(not "..expr..")"..tr))); end function compile_local(form,is_stmt)if (not is_stmt) then error("Cannot compile local variable declaration as an expression"); end local lh=compile(form[0]);local tr=terminator(true);local keyword=(((current_target=="js") and "var ") or "local ");if (form[1]==nil) then return((keyword..lh..tr)); else local rh=compile(form[1],false);return((keyword..lh.."="..rh..tr)); end  end function compile_while(form,is_stmt)if (not is_stmt) then error("Cannot compile WHILE as an expression"); end local condition=compile(form[0],false);local body=compile_body(array_sub(form,1));return((((current_target=="js") and ("while("..condition..")"..body)) or ("while "..condition.." do "..body.." end "))); end function compile_list(forms,is_stmt,is_quoted)if is_stmt then error("Cannot compile LIST as a statement"); end local i=0;local str=(((current_target=="lua") and "{") or "[");while (i<array_length(forms)) do local x=forms[i];local x1=((is_quoted and quote_form(x)) or compile(x,false));if ((i==0) and (current_target=="lua")) then str=(str.."[0]="); end str=(str..x1);if (i<(array_length(forms)-1)) then str=(str..","); end i=(i+1); end return((str..(((current_target=="lua") and "}") or "]"))); end function compile_to_string(form)return((((type(form)=="string") and ("\""..form.."\"")) or (form..""))); end function quote_form(form)if ((type(form)=="string") and (string_ref(form,string_start())=="\"")) then return(form); elseif is_atom(form) then return(compile_to_string(form)); elseif (form[0]=="unquote") then return(compile(form[1],false)); else return(compile_list(form,false,true)); end  end function compile_quote(forms,is_stmt)if is_stmt then error("Cannot compile quoted form as a statement"); end if (array_length(forms)<1) then error("Must supply at least one argument to QUOTE"); end return(quote_form(forms[0])); end function compile_macro(form,is_stmt)if (not is_stmt) then error("Cannot compile macro definition as an expression"); end local tmp=current_target;current_target=current_language;eval(compile_function(form,true));local name=form[0];local register={[0]="set",{[0]="get","macros",compile_to_string(name)},name};eval(compile(register,true));current_target=tmp; end function compile(form,is_stmt)if (form==nil) then return(""); elseif is_atom(form) then return(compile_atom(form,is_stmt)); elseif is_call(form) then if (is_operator(form) and is_stmt) then error(("Cannot compile operator application as a statement")); elseif is_operator(form) then return(compile_operator(form)); elseif is_macro_definition(form) then compile_macro(array_sub(form,1),is_stmt);return(""); elseif is_special(form) then local fn=special[form[0]];return(fn(array_sub(form,1),is_stmt)); elseif is_macro_call(form) then local fn=macros[form[0]];local form=fn(array_sub(form,1));return(compile(form,is_stmt)); else return(compile_call(form,is_stmt)); end  else error(("Unexpected form: "..to_string(form))); end  end function compile_file(filename)local form;local output="";local s=make_stream(read_file(filename));while true do form=read(s);if (form==eof) then break; end output=(output..compile(form,true)); end return(output); end function usage()print("usage: x input [-o output] [-t target]");exit(); end args=array_sub(arg,1);if (array_length(args)<1) then usage(); end input=args[0];output=false;i=1;while (i<array_length(args)) do local arg=args[i];if ((arg=="-o") or (arg=="-t")) then if (array_length(args)>(i+1)) then i=(i+1);local arg2=args[i];if (arg=="-o") then output=arg2; else current_target=arg2; end  else print("missing argument for",arg);usage(); end  else print("unrecognized option:",arg);usage(); end i=(i+1); end if (output==false) then local name=string_sub(input,string_start(),string_find(input,"."));output=(name.."."..current_target); end define_operators();define_special();write_file(output,compile_file(input));