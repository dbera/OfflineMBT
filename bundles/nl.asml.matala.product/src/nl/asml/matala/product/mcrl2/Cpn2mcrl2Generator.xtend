package nl.asml.matala.product.mcrl2

class Cpn2mcrl2Generator
{
    def generateCpn2mcrl2(String modelFile, String typesFile)
    {
        return
        '''
        import json
        import os, shutil
        import subprocess
        import sys
        import time
        from translator import Translator
        from argparse import ArgumentParser
        
        base_folder = 'temp'
        prop_folder = f'{base_folder}\\properties\\'
        lps_folder = f'{base_folder}\\lps\\'
        mcrl2_folder = f'{base_folder}\\mcrl2\\'
        pbes_folder = f'{base_folder}\\pbes\\'
        evidence_folder = f'{base_folder}\\evidence\\'
        
        
        class ModelChecker():
            def __init__(self, model, threads, solver, types_file):
                self.create_folders()
        
                self.json_file = model
        
                self.default_lps = f'{lps_folder}default.lps'
        
                self.g = Translator(mcrl2_folder, model, types_file)
                self.make_lps(self.g.generate(), self.default_lps)
        
                self.threads = threads
                self.solver = solver
        
                with open('properties.json', 'r') as file:
                    self.config = json.load(file)
        
            def create_folders(self):
                try:
                    shutil.rmtree(base_folder)
                except:
                    pass
                os.mkdir(base_folder)
                os.mkdir(prop_folder)
                # os.mkdir(prop_folder + 'simple\\')
                # os.mkdir(prop_folder + 'specific\\')
                # os.mkdir(prop_folder + 'static\\')
                os.mkdir(lps_folder)
                os.mkdir(mcrl2_folder)
                os.mkdir(evidence_folder)
                # os.mkdir(pbes_folder)
        
            def make_lps(self, model, lps_name):
                model_name = f'{mcrl2_folder}model.mcrl2'
                with open(model_name, 'w') as f:
                    f.write(model)
        
                subprocess.run(['mcrl22lps', '-l', 'regular2', model_name, lps_name], capture_output=True)
        
            def check_property(self, prop_name, arguments=None, counter_example=False):
                prop = self.config['properties'][prop_name]
                name = prop['name']
                property = prop['template']
                condition = prop['condition'] if 'condition' in prop.keys() else ''
                for i in range(len(prop['arguments'])):
                    name = name.replace(f'arg{i+1}', str(arguments[i]))
                    
                    property = property.replace(f'arg{i+1}', str(arguments[i]))
                    if prop['type'] == 'exception':
                        condition = condition.replace(f'arg{i+1}', arguments[i])
        
                if counter_example:
                    print(f'   - creating a counterexample for {name}')
                elif args.verbose:
                    print(f' - Running {name}')
        
                filename = f'{prop_folder}prop{hash(name)}.mcf'
                with open(filename, 'w') as file:
                    file.write(property)
                    # file.close()
        
                if prop['type'] == 'exception':
                    g = self.g.copy()
                    g.add_exception(condition)
                elif prop['type'] == 'expose':
                    g = self.g.copy()
                    g.add_expose(arguments[0], arguments[1][0], arguments[1][1:])
                else:
                    g = self.g.copy()
                
                lps = lps_folder + 'temp.lps'
        
                if (counter_example):
                    g.set_expose_all()
                model = g.generate()
                self.make_lps(model, lps)
                
                res = self.run_mcrl2(filename, lps, counter_example=counter_example, name=name)
                if res == 'False':
                    if args.c and not counter_example:
                        print("   - false, creating counterexample")
                        model_checker.check_property(prop_name, arguments=arguments, counter_example=True)
                    elif args.verbose:
                        print("   - false")
                    else:
                        print(f'{name}: false')
                return res
                
            def check_reachability(self):
                print('Checking reachability')
                with open(self.json_file, 'r') as file:
                    transitions = json.load(file)['transitions']
                
                template = self.config['reachability']['template']
        
                count = 0
        
                for transition in transitions:
                    prop = template.replace('arg1', transition)
        
                    filename = f'{prop_folder}reach_{transition}.mcf'
                    with open(filename, 'w') as file:
                        file.write(prop)
        
                    res = self.run_mcrl2(filename)
        
                    if res == 'False':
                        print(f'   - False: {transition} unreachable')
                    elif res == 'True':
                        if args.verbose:
                            print(f'   - {transition} reachable')
        
                        count += 1
                    else:
                        return False
                    
                return count == len(transitions)
            
            def check_termination(self):
                print('Checking termination')
                
                template = self.config['termination']['template']
        
                count = 0
        
                prop = template
        
                filename = f'{prop_folder}termination.mcf'
                with open(filename, 'w') as file:
                    file.write(prop)
        
                res = self.run_mcrl2(filename)
        
                return res == 'True'
        
            def run_mcrl2(self, prop, lps=None, counter_example=False, name=None):
                if lps == None:
                    lps = self.default_lps
                if name == None:
                    name = hash(prop)
                else:
                    name = name.replace(' ', '_')
        
                if counter_example:
                    pbes = subprocess.run(['lps2pbes', '-c', '-f', prop, lps], capture_output=True)
                    result = subprocess.run(['pbessolve', f'--threads={self.threads}', f'-s{self.solver}', '-f', lps, f'--evidence-file={evidence_folder}evidence.lps'], input=pbes.stdout, capture_output=True)
                    print(f'   - writing counterexample to: {name}.lps')
                else:
                    pbes = subprocess.run(['lps2pbes', '-f', prop, lps], capture_output=True)
                    result = subprocess.run(['pbessolve', f'--threads={self.threads}', f'-s{self.solver}'], input=pbes.stdout, capture_output=True)
        
        
                res = result.stdout.decode('utf-8')
                if result.stderr != b'':
                    print(result.stderr.decode('utf-8'))
                    return 'Invalid'
                elif 'false' in res:
                    return 'False'
                elif 'true' in res:
                    return 'True'
                else:
                    return 'Invalid'
        
        if __name__ == '__main__':
        
            arg_parser = ArgumentParser(prog='Model checker for CPN models', epilog='Made by Noah van Uden for ASML')
        
            arg_parser.add_argument('-c', action='store_true', help='Produce counter examples')
            arg_parser.add_argument('-t', '--threads', help='Number of threads used (default: %(default)s)', default=3)
            arg_parser.add_argument('-s', '--solver', help='Solver used (check mcrl2.org) (default: %(default)s)', default=2)
            arg_parser.add_argument('-v', '--verbose', action='store_true')
            arg_parser.add_argument('-e',  help='Translate only', action='store_true')
            arg_parser.add_argument('--termination', action='store_true', help='Check for termination')
            arg_parser.add_argument('--reachability', action='store_true', help='Check for reachability of all tasks')
            arg_parser.add_argument('--types', help='Override types file, should be a .json file', default='')
            arg_parser.add_argument('--model', help='Override model file to check, should be a mCRL2 file', default='')
        
            args = arg_parser.parse_args()
        
            if 'help' in args:
                arg_parser.print_help()
        
            model = args.model if args.model else 'BMMO_Simple_mcrl2.json'
            types = args.types if args.types else 'BMMO_Simple_types.json'
        
            model_checker = ModelChecker(model, args.threads, args.solver, types)
        
            if args.e:
                sys.exit()
        
            with open('to_check.json', 'r') as file:
                properties = json.load(file)
        
            start = time.time()
        
            valid = 0
            invalid = 0
            total = 0
        
            if args.reachability:
                if model_checker.check_reachability():
                    print('All transitions are reachable')
                else:
                    print('Not all transitions are reachable!')
            
            if args.termination:
                if model_checker.check_termination():
                    print('Model terminates')
                else:
                    print('Model does not terminate!')
        
        
            for prop in properties:
                if prop['prop'] == '':
                    continue
                res =  model_checker.check_property(prop['prop'], arguments=prop['args'])
                if res == 'True':
                    valid += 1
                elif res == 'Invalid':
                    invalid += 1
                total += 1
        
                print(f'Satisfied properties: {valid}/{total}')
                print(f'Invalid properties: {invalid}')
            
            end = time.time()
        
            print(f'Time elapsed: {end - start}')

        '''
    }
    
    def generateTranslator() {
        return
        '''
        import os, json
        
        class Translator():
            def __init__(self, mcrl2_folder, json_file, types_file):
                self.mcrl2_folder = mcrl2_folder
                self.json_file = json_file
                self.types_file = types_file
                self.filename = f'{mcrl2_folder}{os.path.basename(__file__)}_{os.path.basename(json_file)}.mcrl2'
                
                self.exception = []
                self.exposes = {}
                self.expose_all = False
        
                with open(json_file, 'r') as file:
                    cpn = json.load(file)
                self.init = cpn['init']
                with open(types_file, 'r') as file:
                    self.types = json.load(file)
        
                for types in self.types['record']:
                    for stype in self.types['record'][types]['vars']:
                        self.types['record'][types]['vars'][stype] = self.translate_types(self.types['record'][types]['vars'][stype])
        
                tempMaps = []
                
                for maps in self.types['maps']:
                    tempMaps.append((maps[0], maps[1]))
        
                self.types['maps'] = tempMaps
                    
                self.places = cpn['places']
                for p in self.places:
                    self.places[p] = self.translate_types(self.places[p])
        
                self.transitions = cpn['transitions']
                self.places_id = list(self.places.keys())
        
            def copy(self):
                return Translator(self.mcrl2_folder, self.json_file, self.types_file)
            
            def set_expose_all(self):
                self.expose_all = True
        
            def add_exception(self, condition):
                self.exception.append(condition)
        
            def add_expose(self, transition, queue, types):
                msg_type = self.places[queue]
                
                for type in types:
                    msg_type = self.types['record'][msg_type]['vars'][type]
        
                self.exposes[transition] = {'queue': queue, 'msg_type': msg_type, 'types': types}
        
            def print_expr_bindings(self, t):
                return ' && '.join(map(
                        lambda p : f'{self.print_expr_binding(p)} in m_{p}',
                        self.transitions[t]['pre']
                ))
          
            def print_init(self):
                return ',\n'.join(map(
                    lambda p: f'        m_{p} = [{f'{', '.join(map(
                        lambda e: f'{p}({self.parse_expr(e, self.places[p])})',
                        self.init[p]
                    ))}' if p in self.init else ''}]',
                    self.places_id
                ))
            
            def parse_or_default(self, t, expr, etype):
                if t in expr:
                    ret = self.parse_expr(expr[t], self.types['record'][etype]['vars'][t])
                else:
                    ret = self.defaultValue(self.types['record'][etype]['vars'][t])
        
                return ret
            
            def parse_expr(self, expr, etype):
        
                if etype in self.types['enum'] or etype in ['Int', 'Nat', 'Bool']:
                    return expr
                
                if type(expr) is str:
                    return expr
                
                if etype[:5] == 'List(':
                    return f'[{', '.join(map(
                        lambda e: self.parse_expr(e, etype[5:-1]),
                        expr
                    ))}]'
                
                
        
                res = ''
                res += f'{etype}('
        
                res += ', '.join(map(
                    lambda t: self.parse_or_default(t, expr, etype),
                    self.types['record'][etype]['vars']
                ))
                maps = self.types['record'][etype]['maps']
                if bool(maps) and res[-1] != '(':
                    res += ', '
                for t in maps:
                    if (type(expr[t]) is str):
                        if expr[t][:9] == 'deleteKey':
                            temp = self.types['record'][etype]['maps'][t]
                            res += f'{expr[t][:9]}_{temp['from']}_{temp['to']}{expr[t][9:]}'
                        else:
                            res += expr[t]
                    else:
                        res += '['
                        res += ', '.join(map(
                            lambda e: f'kv({self.parse_expr(e, self.types['record'][etype]['maps'][t]['from'])}, {self.parse_expr(expr[t][e], self.types['record'][etype]['maps'][t]['to'])})',
                            expr[t]
                        ))
                        res += ']'
        
                res += ')'
        
                return res
        
            def print_mappings(self):
                to_print = self.print_remove_token_from_list()
        
                for (f, t) in self.types['maps']:
                    to_print += self.print_get_delete(f, t)
        
                return to_print
            
            def print_remove_token_from_list(self):
                return """
                map remove_token_from_list: token # List(token) -> List(token);
                var p, p_old: token;
                    l: List(token);
                eqn remove_token_from_list(p, p_old |> l) = if(p == p_old, l, p_old |> remove_token_from_list(p, l));
                    remove_token_from_list(p, []) = [];
                """
            
            def print_get_delete(self, f, t):
                return """
                map get: List(kv_arg1_arg2) # arg1 -> arg2;
                var pk: arg1;
                    pv: arg2;
                    l: List(kv_arg1_arg2);
                    n: arg1;
                eqn pk == n -> get(kv(pk, pv) |> l, n) = pv;
                    pk != n -> get(kv(pk, pv) |> l, n) = get(l, n);
        
                map deleteKey_arg1_arg2: List(kv_arg1_arg2) # arg1 -> List(kv_arg1_arg2);
                var ip_arg1_arg2, i_arg1_arg2: arg1;
                    item_arg1_arg2: arg2;
                    l_arg1_arg2: List(kv_arg1_arg2);
                eqn deleteKey_arg1_arg2([], i_arg1_arg2) = [];
                    deleteKey_arg1_arg2(kv(ip_arg1_arg2, item_arg1_arg2) |> l_arg1_arg2, i_arg1_arg2) = if(i_arg1_arg2 == ip_arg1_arg2, l_arg1_arg2, kv(ip_arg1_arg2, item_arg1_arg2) |> deleteKey_arg1_arg2(l_arg1_arg2, i_arg1_arg2));
                """.replace('arg1', f).replace('arg2', t)
            
            def print_marking(self):
                return 'List(token)'
            
            def print_transition(self, t):
                trans = f'sum b: b_{t} . ({self.print_expr_bindings(t)}{self.print_guards(t)}) ->'
                trans += '\n            ('
        
                if self.expose_all:
                    trans += f'input([{
                        ', '.join(map(
                            lambda p: f'{p}({p}_col(b))',
                            self.transitions[t]['pre']
                        ))
                    }]) . '
                    trans += f'output([{
                        ', '.join(map(
                            lambda p: f'{p}({self.parse_expr(self.transitions[t]['post'][p], self.places[p])})',
                            self.transitions[t]['post']
                        ))
                    }]) . '
        
                trans += f'{t}'
        
                if t in self.exposes:
                    temp = self.parse_expr(self.transitions[t]['post'][self.exposes[t]['queue']], self.places[self.exposes[t]['queue']])
                    for n in self.exposes[t]['types']:
                        temp = f'{n}({temp})'
                    trans += f'({temp})'
        
                
        
                trans += ' . CPN('
        
                # req(Request(LotContext(lot_type(get(lots(lot_schedule_col(b)), idx(lot_sch_idle_col(b)))), idx(lot_sch_idle_col(b)))))
        
                for p in self.places_id:
                    update = f'm_{p}'
                    if p in self.transitions[t]['pre']:
                        update = f'remove_token_from_list({p}({p}_col(b)), {update})'
                    if p in self.transitions[t]['post']:
                        update = f'{p}({self.parse_expr(self.transitions[t]['post'][p], self.places[p])}) |> {update}'
        
                    trans += f'm_{p} = {update}, ' if p in p in self.transitions[t]['pre'] or p in p in self.transitions[t]['post'] else ''
        
        
                trans = trans[:-2]
                trans += '))'
                return trans
        
            def print_places(self):
                return ',\n'.join(map(
                    lambda p: f'        m_{p}: {self.print_marking()}',
                    self.places_id
                ))
        
            def print_snippet(self, snippet):
                return open(f'generators/snippets/{snippet}', 'r').read()
            
            def print_place(self, p, t=None):
                # return f'{p}({', '.join(
                #     map(
                #         lambda var: f'{var}: {self.places[p][var]}',
                #         self.places[p]
                #     )
                # )})'
                return f'{p}({self.places[p]})'
        
            def print_binding(self, t):
                return f'sort b_{t} = struct b_{t}({', '.join(
                    map(
                        lambda p: f'{p}_col: {self.places[p]}',
                        self.transitions[t]['pre']
                    )
                )});\n'
            
            def print_expr_binding(self, p):
                return (f'{p}({p}_col(b))')
            
            def print_updates(self, t):
                return ', '.join(map(
                    lambda p: self.transitions[t]['post'][p] if self.transitions[t]['post'][p] else self.print_expr_binding(p),
                    self.transitions[t]['post']
                ))
            
            def print_guards(self, t):
                return f' && ({self.transitions[t]['guard']})' if self.transitions[t]['guard'] else ''
            
            def print_types(self):
                res = ''
                for mapping in self.types['maps']:
                    (k, v) = mapping
                    res += f'sort kv_{k}_{v} = struct kv(k: {k}, v: {v});\n'
                res += '\n'
                for type in self.types['enum']:
                    res += f'sort {type} = struct {' | '.join(self.types['enum'][type])};\n'
                res += '\n'
        
                for type in self.types['record']:
                    res += f'sort {type} = struct {type}('
                    vars = ', '.join(map(
                        lambda st: f'{st}: {self.types['record'][type]['vars'][st]}',
                        self.types['record'][type]['vars']
                    ))
                    maps = ', '.join(map(
                        lambda st: f'{st}: List(kv_{self.types['record'][type]['maps'][st]['from']}_{self.types['record'][type]['maps'][st]['to']})',
                        self.types['record'][type]['maps']
                    ))
                    if vars != '' and maps != '':
                        res += vars + ', ' + maps
                    else:
                        res += vars + maps
                    res += ');\n'
        
                return res + '\n'
            
            def write(self, exception=None) :
                if exception != None:
                    self.filename = exception[0] + self.filename
                with open(self.filename, 'w') as f:
                    if exception != None:
                        f.write(self.generate(exception=exception))
                    else:
                        f.write(self.generate())
        
                return self.filename
            
            def generate(self, exception=None):
                
                model = ''
        
                model += 'sort Unit = struct unit;\n\n'
        
                model += self.print_types()
        
                model += self.print_mappings()
        
                # model += self.print_snippet('add_layer.mcrl2'))
        
                # Print places
                model += '% Set of places (P)\n'
                model += 'sort token = struct None\n            | '
                model += '\n            | '.join(map(self.print_place, self.places))
                model += ';\n\n'
        
                # Print bindings
                model += '% Define possible bindings per transition\n'
                for t in self.transitions:
                    model += self.print_binding(t)
                model += '\n'
        
                # Print transitions
                model += '% Set of transitions (T)\n'
                model += 'act\n    '
                model += ';\n    '.join(map(
                    lambda t: f'{t}: {self.exposes[t]['msg_type']}' if t in self.exposes else t,
                    self.transitions
                ))
                model += ';'
                if self.exception:
                    model += '\n    raise_exception;'
                if self.expose_all:
                    model += '\n    input: List(token);'
                    model += '\n    output: List(token);'
        
                model += '\n\n'
        
                model += f'proc\n    CPN(\n{self.print_places()}\n    ) =\n        '
        
                for exception in self.exception:
                    model += f'({exception}) -> raise_exception.delta +\n\n        '
        
                model += ' +\n\n        '.join(map(self.print_transition, self.transitions))
                model += ';\n\n'
        
                model += f'init\n    CPN(\n{self.print_init()}\n    );'
        
                # subprocess.run(['mcrl22lps', '-e'], input=model.encode('utf-8'))
                return model
        
            def translate_types(self, t):
                if '[]' in t:
                    return self.translate_types(f'List({self.translate_types(t[:-2])})')
        
                match t:
                    case 'int':
                        return 'Int'
                    case 'nat':
                        return 'Nat'
                    case 'bool':
                        return 'Bool'
                    case 'string':
                        return 'Unit'
                    case _:
                        return t
                    
            def defaultValue(self, etype):
                if etype == 'Int':
                    return '0'
                if etype == 'Nat':
                    return '1'
                if etype == 'Bool':
                    return 'true'
                if etype == 'Unit':
                    return 'unit'
                if etype[:5] == 'List(':
                    return '[]'
                if etype in self.types['enum']:
                    return self.types['enum'][etype][0]
                if etype in self.types['record']:
                    value = ', '.join(map(
                        lambda t: f'{self.defaultValue(self.types['record'][etype]['vars'][t])}',
                        self.types['record'][etype]['vars']
                    ))
                    if value != '':
                        value += ', '
                    value += ', '.join(map(
                        lambda t: f'[]',
                        self.types['record'][etype]['maps']
                    ))
        
                    if value[-2:] == ', ':
                        value = value[:-2]
                    return f'{etype}({value})'
                raise Exception('Type not found')
        '''
    }
    
    def generateProperties() {
        return 
        '''
        {
            "reachability": {
                "arguments": ["Task"],
                "template": "<true*><arg1>true"
            },
            "inevitable": {
                "arguments": ["Task"],
                "template": "mu X . ([!arg1]X && <true>true)"
            },
            "termination": {
                "arguments": [],
                "template": "mu X . ([true]X)"
            },
            "properties": {
                "A_at_least_n_times": {
                    "name": "arg1 occurs at least arg2 times",
                    "type": "simple",
                    "arguments": ["Task", "Num"],
                    "template": "nu X(c:Nat=0).(val(c >= arg2) || ([arg1]X(c+1) && [!arg1]X(c) && mu Y . ([!arg1]Y && <true>true)))"
                },
                "A_at_most_n_times": {
                    "name": "arg1 occurs at most arg2 times",
                    "type": "simple",
                    "arguments": ["Task", "Num"],
                    "template": "nu X(c:Nat=0) . ([arg1](val(c + 1 <= arg2) && X(c+1)) && [!arg1]X(c))"
                },
                "A_exactly_n_times": {
                    "name": "arg1 occurs exactly arg2 times",
                    "type": "simple",
                    "arguments": ["Task", "Num"],
                    "template": "nu X(c: Nat = 0) . ((val(c < arg2)   && ([arg1]X(c+1) && [!arg1]X(c) && mu Y . ([!arg1]Y && <true>true))) || (val(c >= arg2)) && ([true*][arg1]false))"
                },
                "A_not_more_often_than_B": {
                    "name": "arg1 not more often than arg2",
                    "type": "simple",
                    "arguments": ["Task", "Task"],
                    "template": "nu X(a:Nat=0, b:Nat=0) . ([arg1](val(a + 1 <= b) && X(a+1, b)) && [arg2]X(a, b+1) && [!(arg1 || arg2)]X(a, b))"
                },
                "A_not_before_B": {
                    "name": "arg1 not before arg2",
                    "type": "simple",
                    "arguments": ["Task", "Task"],
                    "template": "[!arg2*][arg1]false"
                },
                "Q_at_most_n_items": {
                    "name": "arg1 has at most arg2 item(s)",
                    "type": "exception",
                    "arguments": [["Queue"], "num"],
                    "condition": "#m_arg1 > arg2",
                    "template": "[true*][raise_exception]false"
                },
                "c_ensures_A_before_B": {
                    "name": "If arg1 produces an item with arg2 == arg3, then arg4 should occur before arg5",
                    "type": "expose",
                    "arguments": ["Task", "[Types]", "Constant", "Task", "Task"],
                    "template": "[true*][arg1(arg3)] mu X . ([!arg4]X && [arg5]false && <true>true)"
                },
                "A_can_only_happen_after_B": {
                    "name": "Task arg1 can only occur after task arg2 has occurred",
                    "type": "simple",
                    "arguments": ["Task", "Task"],
                    "template": "[(!arg2)*][arg1]false"
                },
                "When_A_then_eventually_B": {
                    "name": "When arg1 occurs, then eventually arg2 occurs",
                    "type": "simple",
                    "arguments": ["Task", "Task"],
                    "template": "<true*>[arg1] mu X . ([!arg2]X && <true>true)"
                }
            }
        }
        '''
    }
    
    def generateToCheck() 
    {
        return
        '''
        [
            {"prop": "", "args": []}
        ]
        '''
    }
}