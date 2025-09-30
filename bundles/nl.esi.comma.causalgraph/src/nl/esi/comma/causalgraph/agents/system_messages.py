def should_code_merge_prompt(code_snippets: list[str]) -> bool:
    """
    Checks if two pieces of could should merge into a parameterized step definition.

    Args:
        code_snippets (list[str]): List of code snippets to be merged into a single step definition.
    Returns:
        bool: Boolean if two pieces of code should merge into a paramaterized step definition.
    """

    prompt = """
    You should check if two pieces are similar enough to merge and paramaterize in a step
    definition. If so you should just return True and if not then you should return False. Do not
    return more than the Boolean.

    Rules:
    1. Only return True or False, nothing else.
    2. The code snippets should be similar enough to be merged into a single step definition with parameterization.
    3. The code snippets can be different in logic or structure, but there should be overlaping pieces of code that can be paramaterized
    4. With large pieces of code, it is even more important that pieces of the code are similar in logic, not the entire code has to be similar.
    5. Be very lenient code should almost always be merged only pieces of code that are very far apart shouldnt be merged!

    First I will present 2 examples with two code snippets that should be merged and parameterized in a step definition:
    Code snippet 1:
    bool y = true;
    float z = 0.85;
    y = function42(z);
    if(y) {
        x = x + 4;
        z = function2(x);
    }
    else { z = function2(x); }
    z = z + 3.7;
    h = test-interface::f1(z, y);

    Code snippet 2:
    bool y = true;
    float z = 0.5;
    y = function1(z);
    if(y) {
        x = x + 6;
        z = function2(x);
    }
    z = z + 3.7;
    h = test-interface::f1(z, y);

    Output:
    True

    code snippet 1:
    int expectedBalance = espressoCost + espressoCost;
    EXPECT_EQ(machine.GetBalance(), expectedBalance);

    code snippet 2:
    «EXPECT_EQ(machine.GetBalance(), 0);

    Output:
    True

    Second I will present an example that should not be merged and paramaterized in a step
    definition:
    Code snippet 1:
    bool y = true;
    float z = 0.85;
    y = function42(z);
    if(y) {
        x = x + 4;
        z = function2(x);
    }
    else { z = function2(x); }
    z = z + 3.7;
    h = test-interface::f1(z, y);

    Code snippet 2:
    float y = 10;
    float z = 0.85;

    for y in range(y):
        z += 1;

    Output:
    False
    """

    prompt += f"""No I will present two code snippets where you should decide if they should be merged and parameterized in a step
    definition:
    Code snippet 1:
    {code_snippets[0]}

    Code snippet 2:
    {code_snippets[1]}

    Output:
    """
    return prompt


rules_aritmethic_multiple_steps = """4 Rules variable dependencies and arithmetic between multiple steps:
When a variable's value depends on calculations or assignments from previous steps, you MUST resolve these to concrete values by:
4.1 Using initialized values from the causal graph (e.g., valueA = 2, valueB = 5, valueC = 3)
4.2 Analyzing step bodies from previous steps with the same test-case ID (T) to find variable assignments
4.3 Substitute all known values from the causal graph or earlier calculations
4.4 When you should do arithmetic between steps this the only case where you shouldn't only output json but you should ALWAYS provide an "Explanation:" section showing digit-by-digit arithmetic: Example: finalResult = valueA + valueB + valueC + valueA + 5 = 2 + 5 + 3 + 2 + 5 = 17
4.5 Never guess values - every calculation must be traceable to the source
4.6 For expressions like "processedValue - firstInput" or "processedValue + 10", you MUST calculate the concrete result
4.7 CRITICAL STEP ORDERING RULE: The order of steps is CRITICALLY important. When looking for variable values in previous steps, you MUST use the value from the step with the HIGHEST step number that is LOWER than the current step number within the SAME test case (T).

For example, if the current step is "T4 step 13" and there are previous steps "T4 step 4" and "T4 step 11", you MUST use the value from "T4 step 11" because 11 is closer to 13 than 4.

I will present an example how to do this:
Initialized variables from causal graph:
- alpha: int (initial value: 2)
- beta: int (initial value: 5)
- gamma: int (initial value: 3)

--- Node n1 Original Scenarios ---
scenario causal_graph_T1 step 1:
    int result = alpha + beta + gamma + alpha + 5;

scenario causal_graph_T1 step 3:
    int result = alpha + alpha;

Scenario causal_graph_T2 step 1:
    int result2 = alpha + beta + gamma;

SCENARIOS TO MERGE:
scenario causal_graph_T1 step 2:
    executeAction(result);

scenario causal_graph_T2 step 2:
    int temp = 5;
    executeAction(temp);

scenario causal_graph_T2 step 3:
    executeAction(result2 - temp);

Output the reasoning in the case you need to combine multiple variables from different steps, expand every arithmetic expression digit-by-digit until you get a concrete primitive.
Output:
Explanation:
scenario causal_graph_T1 step 2:
    result = alpha + beta + gamma + alpha + 5
    result = (2 + 5 + 3 + 2 + 5) = 17

scenario causal_graph_T2 step 2:
    result2 = alpha + beta + gamma
    result2 = (2 + 5 + 3) = 10

scenario causal_graph_T2 step 3:
    result3 = result2 - temp
    result3 = (10 - 5) = 5

Incorrect explanation:
scenario causal_graph_T1 step 2:
    result = alpha + alpha
    result = (2 + 2) = 4

Return step definition JSON:
{
"step-arguments": {"scenario causal_graph_T1, step 2": {"_result": 17}, "scenario causal_graph_T2, step 2": {"_result": 10}, "scenario causal_graph_T2, step 3": {"_result": 5}},
"step-parameters": {"_result": "int"},
"step-body": "executeAction(_result);"
}
"""

example_multiple_scenarios_complex_data_type_if_else = """
EXAMPLE - Multiple Scenarios 1:
Snippet 1:
Variable = value1;
val = true;

Snippet 2:
Variable = value2;

Output:
{
    "step-arguments": {
        "scenario causal_graph_T1, step 0": {"_includeTypeA": true, "_typeALevel": 2, "_typeAFlag": true, "_includeTypeB": true, "_paramX": 0.15, "_typeBLevel": 1, "_paramY": 0.9, "_typeBFlag": true, "_includeTypeC": true, "_typeCLevel": 1, "_paramZ": 0.45, "_typeCFlag": true},
        "scenario causal_graph_T2, step 0": {"_includeTypeA": true, "_typeALevel": 3, "_typeAFlag": true, "_includeTypeB": true, "_paramX": 0.15, "_typeBLevel": 2, "_paramY": 0.9, "_typeBFlag": true, "_includeTypeC": false, "_typeCLevel": 0, "_paramZ": 0.0, "_typeCFlag": false}
    },
    "step-parameters": {
        "_param1": "string",
    },
    "step-body":"Variable = param; if (_param1 == constant1) {variable = value1; val = true;} elif  (_param1 == constant2) {variable = value2;} else {Throw an error ;}"
}
"""

example_multiple_scenarios_complex_data_types = """
EXAMPLE - Multiple Scenarios 1:
Input:
scenario causal_graph_T4 step 2:
    step-body:
    «
    Entity typeAInstance(TypeA(Level::HIGH, true), {}, {});
    Entity typeBInstance({}, TypeB(0.15, Level::LOW, 0.9, true), {});
    Entity typeCInstance({}, {}, TypeC(Level::HIGH, 0.45, true));
    std::vector<Entity> entities;
    entities.push_back(typeAInstance);
    entities.push_back(typeBInstance);
    entities.push_back(typeCInstance);
    processor.ProcessItem(typeAInstance);
    processor.ProcessItem(typeBInstance);
    processor.ProcessItem(typeCInstance);
    »
scenario causal_graph_T4 step 9:
    step-body:
    «
    Entity typeAInstance(TypeA(Level::HIGH, true), {}, {});
    Entity altInstance({}, TypeB(0.5, Level::MED, 0.3, true), {});
    entities.clear();
    entities.push_back(typeAInstance);
    entities.push_back(typeBInstance);
    processor.ProcessItem(typeAInstance);
    processor.ProcessItem(typeBInstance);
    »

Output:
{
    "step-arguments": {
        "scenario causal_graph_T1, step 0": {"_includeTypeA": true, "_typeALevel": 2, "_typeAFlag": true, "_includeTypeB": true, "_paramX": 0.15, "_typeBLevel": 1, "_paramY": 0.9, "_typeBFlag": true, "_includeTypeC": true, "_typeCLevel": 1, "_paramZ": 0.45, "_typeCFlag": true},
        "scenario causal_graph_T2, step 0": {"_includeTypeA": true, "_typeALevel": 3, "_typeAFlag": true, "_includeTypeB": true, "_paramX": 0.15, "_typeBLevel": 2, "_paramY": 0.9, "_typeBFlag": true, "_includeTypeC": false, "_typeCLevel": 0, "_paramZ": 0.0, "_typeCFlag": false}
    },
    "step-parameters": {
        "_includeTypeA": "bool",
        "_typeALevel": "int",
        "_typeAFlag": "bool",
        "_includeTypeB": "bool",
        "_paramX": "double",
        "_typeBLevel": "int",
        "_paramY": "double",
        "_typeBFlag": "bool",
        "_includeTypeC": "bool",
        "_typeCLevel": "int",
        "_paramZ": "double",
        "_typeCFlag": "bool"
    },
    "step-body": "std::vector<Entity> entities;\\nif (_includeTypeA) {\\nLevel l = static_cast<Level>(_typeALevel);\\nEntity typeAInstance(TypeA(l, _typeAFlag), {}, {});\\nentities.push_back(typeAInstance);\\nprocessor.ProcessItem(typeAInstance);\\n}\\nif (_includeTypeB) {\\nLevel l = static_cast<Level>(_typeBLevel);\\nEntity typeBInstance({}, TypeB(_paramX, l, _paramY, _typeBFlag), {});\\nentities.push_back(typeBInstance);\\nprocessor.ProcessItem(typeBInstance);\\n}\\nif (_includeTypeC) {\\nLevel l = static_cast<Level>(_typeCLevel);\\nEntity typeCInstance({}, {}, TypeC(l, _paramZ, _typeCFlag));\\nentities.push_back(typeCInstance);\\nprocessor.ProcessItem(typeCInstance);\\n}"
}
"""

example_multiple_scenarios_sum_variables = """
EXAMPLE - Multiple Scenarios 2 (Generate a sum out of variables (only if the variables are initialized in the causal graph)):
Variable types from causal graph:
- alpha: int
- beta: int
- gamma: int

scenario causal_graph_T1 step 0:
    int computedValue = alpha + beta + gamma;
    EXPECT_EQ(actualValue, computedValue);

scenario causal_graph_T2 step 0:
    int computedValue = alpha + beta + gamma + alpha - 5;
    EXPECT_EQ(actualValue, computedValue);

scenario causal_graph_T2 step 2: step-body: «EXPECT_EQ(actualValue, 0);»

Output:
{
    "step-arguments": {
        "scenario causal_graph_T1, step 0": {"_numAlpha": 1, "_numBeta": 1, "_numGamma": 1, "_constant": 0},
        "scenario causal_graph_T2, step 0": {"_numAlpha": 2, "_numBeta": 1, "_numGamma": 1, "_constant": -5},
        "scenario causal_graph_T2, step 2": {"_numAlpha": 0, "_numBeta": 0, "_numGamma": 0, "_constant": 0}
    },
    "step-parameters": {
        "_numAlpha": "int",
        "_numBeta": "int",
        "_numGamma": "int",
        "_constant": "int"
    },
    "step-body": "int computedValue = (_numAlpha * alpha) + (_numBeta * beta) + (_numGamma * gamma) + _constant;\\nEXPECT_EQ(actualValue, computedValue);"
}
"""

example_multiple_scenarios_variable_dependencies = """
EXAMPLE - Multiple Scenarios 3 (Resolving variable dependencies to concrete values with step ordering):

Initialized variables from causal graph:
- alpha: int (initial value: 2)
- beta: int (initial value: 5)
- gamma: int (initial value: 3)

Previous step calculations (from earlier nodes with same test cases):
--- Node n Original Scenarios ---
Scenario causal_graph_T3 step 2:
Step Type: Then
Step Body:
int value = alpha + alpha;  // value = 2 + 2 = 4

Scenario causal_graph_T3 step 5:
Step Type: Then
Step Body:
int value = alpha + beta;  // value = 2 + 5 = 7
EXPECT_EQ(functionCall(), value);

Scenario causal_graph_T4 step 11:
Step Type: Then
Step Body:
int value2 = alpha + beta + gamma + alpha - 5;  // value2 = 2 + 5 + 3 + 2 - 5 = 7
EXPECT_EQ(functionCall(), value2);


Current scenarios to causal_graph:
scenario causal_graph_T3 step 5:
    int baseValue = 5;
    performOperation(baseValue);

scenario causal_graph_T3 step 6:
    int baseValue = 5;
    performOperation(value - baseValue);
    // RESOLUTION: value = 7 (from previous step 5 so not value = 4 from step 2 which also shares the same test case id T3 the order of the steps is important), baseValue = 5, so value - baseValue = 2

scenario causal_graph_T4 step 12:
    performOperation(value2);
    // RESOLUTION: value2 = 7 (from previous step calculation)

Explanation:
- For T3 step 6: value = 2 + 5 = 7, baseValue = 5, so value - baseValue = 2
- For T4 step 12: value2 = 2 + 5 + 3 + 2 - 5 = 7

Output:
{
    "step-arguments": {
        "scenario causal_graph_T3, step 5": {"_value": 5},
        "scenario causal_graph_T3, step 6": {"_value": 2},
        "scenario causal_graph_T4, step 12": {"_value": 7}
    },
    "step-parameters": {
        "_value": "int"
    },
    "step-body": "performOperation(_value);"
}

WRONG EXAMPLE - DO NOT DO THIS (Using variable names/expressions instead of concrete values):
{
    "step-arguments": {
        "scenario causal_graph_T3, step 5": {"_value": 5},
        "scenario causal_graph_T3, step 6": {"_value": "value - baseValue"},
        "scenario causal_graph_T4, step 12": {"_value": "value2"}
    }
}
"""


def generate_step_name_prompt(scenarios: list[str]) -> str:
    """
    Prompt to generate only the step name for merging scenarios.

    Args:
        scenarios (list[str]): List of scenarios to be merged into a single step definition.
    Returns:
        str: Formatted prompt for the LLM to generate only the step name.
    """

    prompt = """You should generate ONLY a step name (descriptive identifier) for the following scenarios.
The step name should be a clear, descriptive identifier that captures the main action or purpose of the scenarios.

STEP NAME RULES:
1. Write the step-name in PascalCase
2. Base the step-name on the provided scenarios
3. Make it descriptive but concise
4. Focus on the main action/purpose, not implementation details
5. If multiple scenarios, find the common purpose that unifies them
6. Avoid technical jargon when possible

Return ONLY the step name as a plain string. No JSON, no explanations, no additional text.

SCENARIOS TO NAME:
"""

    for i, scenario in enumerate(scenarios):
        prompt += f"""scenario {i}:
scenario {scenario["scenario_id"]} step {scenario["step_number"]}:
    {scenario['step_body']}

"""

    prompt += "\nReturn only the step name as a plain string:"
    return prompt


def generate_step_definition_prompt(
    scenarios: list[str],
    overlay_variables: dict[str, str] = None,
    variable_initial_values: dict[str, any] = None,
    source_code: dict[str, str] = None,
    previous_overlay_steps: dict[str, list] = None,
) -> str:
    """
    Prompt to generate step-arguments, step-parameters, and step-body for scenarios (step-name is generated separately).

    Args:
        scenarios (list[str]): List of scenarios to be merged into a single step definition.
        overlay_variables (dict[str, str]): Dictionary mapping variable names to their types from the causal graph.
        variable_initial_values (dict[str, any]): Dictionary mapping variable names to their initial values from the causal graph.
        source_code (dict[str, str]): Dictionary containing source code files (filename -> content).
        previous_overlay_steps (dict[str, list]): Dictionary of original overlay scenario steps from previous nodes.
    Returns:
        str: Formatted prompt for the LLM to generate step-arguments, step-parameters, and step-body.
    """

    prompt = """You should generate step-arguments, step-parameters, and step-body for the following scenarios and parameterize and merge where possible when there are
    multiple scenarios.
First I will present some ground rules you should follow for this process. Secondly, I will present multiple examples of multiple
scenarios that are merged into a single step definition. Thirdly, you will be provided with the source code files to help you understand the
context and structure of the system under test. Use the source code to understand data types, class structures, method signatures, and test
patterns. Lastly, I will present the previous steps of the test cases of current scenarios.
Then I will present scenario(s) that should be merged into a step definition.

Return ONLY valid JSON. No explanations, no markdown, no additional text.

Expected JSON Structure:
{
    "step-arguments": {},
    "step-parameters": {},
    "step-body": "string"
}

RULES:
1. FORMAT: Return ONLY valid JSON. No comments, no markdown, or ```json wrappers. No explanations unless you need to combine multiple steps then provide the reasoning. Escape quotes in step-body with \\", don't escape in step-arguments.

2. GENERAL:
   - Use causal graph variable types and source code for context for the generation of the step-parameters. Keep in mind that the parameter types should be consistent.
   - Keep types consistent across step-arguments, step-parameters, step-body
   - Each parameter has one type only
   - Minimize parameters, keep code simple and readable
   - Only modify original code for parameterization
   - Throw an error for behavior that is possible but not present in these code snippets

3. PARAMETERIZATION:
   - Only parameterize when merging DIFFERENT code pieces
   - Parameter names start with underscore: "_paramName"
   - Every scenario should have all parameters
   - Format the step argumentents, step-parameters and step body as following this example:
   {
    "step-arguments": {
        "scenario causal_graph_T1, step 1": {"_x": 1, "_y": "string2"},
        "scenario causal_graph_T2, step 1": {"_x": 2, "_y": "string"},
    },
    "step-parameters": {
        "_x": "int"
        "_y: "string"
    },
    "step-body": "code body"
    }

4. COMPLEX TYPES:
   - Use primitive types only (int, float, string, bool) in step-arguments
   - For complex types, use string modes with conditionals for example when you have Level::HIGH it becomes: if(_mode == "HIGH") { level = Level::HIGH; } or you should be able to infer the value of the enum from the source code or previous steps
"""
    # prompt += rules_aritmethic_multiple_steps
    # prompt += example_multiple_scenarios_complex_data_types
    # prompt += example_multiple_scenarios_sum_variables
    # prompt += example_multiple_scenarios_variable_dependencies
    prompt += example_multiple_scenarios_complex_data_type_if_else

    """
    # Add source code if available (place early for context)
    if source_code:
        prompt += "\nSOURCE CODE REFERENCE:\n"
        for filename, content in source_code.items():
            prompt += f"\n--- {filename} ---\n"
            prompt += f"{content}\n"
    """

    # Add variable types and initial values if available
    if overlay_variables:
        prompt += "\nInitialized variables from causal graph:\n"
        for var_name, var_type in overlay_variables.items():
            initial_value = variable_initial_values.get(var_name, "N/A") if variable_initial_values else "N/A"
            prompt += f"- {var_name}: {var_type} (initial value: {initial_value})\n"

    # Add previous overlay steps if available
    if previous_overlay_steps:
        prompt += "\nPREVIOUS OVERLAY SCENARIO STEPS (from nodes that provide data dependencies):\n"
        prompt += "Use this information to understand what concrete values previous steps have calculated for the same test cases.\n"
        for node_id, overlay_steps in previous_overlay_steps.items():
            prompt += f"\n--- Node {node_id} Original Scenarios ---\n"
            for step in overlay_steps:
                prompt += f"Scenario {step.get('scenario_id', 'N/A')} step {step.get('step_number', 'N/A')}:\n"
                prompt += f"Step Body:\n{step.get('step_body', 'N/A')}\n\n"

    prompt += "\nSCENARIOS TO MERGE:\n"
    for i, scenario in enumerate(scenarios):
        prompt += f"""scenario {i}:
scenario {scenario["scenario_id"]} step {scenario["step_number"]}:
    {scenario['step_body']}

"""
    prompt += (
        """Return step definition JSON and explanation when you need to combine information from multiple steps:"""
    )
    print(prompt)
    return prompt
