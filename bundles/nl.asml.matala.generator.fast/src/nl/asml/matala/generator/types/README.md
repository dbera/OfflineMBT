# Types-to-Python annotations

A practical guide to describing models, configuring their generated UI fields, and choosing what appears in model summaries.

## Start here

A `.types` file describes your data. An annotation is a small instruction placed above a record or field. It adds information without changing the field's declared type.

```text
@Model
record Task {
    @SchemaTitle
    @F(default="Task1", required=true)
    string name

    @SchemaFlag(label="Status", text="Enabled")
    @F(default=true)
    bool enabled
}
```

In this example:

- `record Task` defines a data type.
- `@Model` documents that the record is a model. Records also generate model classes without this marker.
- `@F` configures a generated field, such as its default value and validation metadata.
- `@SchemaTitle` chooses the field used as the summary title.
- `@SchemaFlag` adds a short flag to the summary when interpreted by the UI runtime.

There are **two separate annotation families**:

1. **UI annotations** choose a field helper and pass it configuration.
2. **Summary annotations** describe the generated `MODEL_SUMMARIES` dictionary.

You can use one UI annotation and multiple summary annotations on the same field.

> This guide describes the repeatable-summary implementation developed for this project. Its Xtend sources and occurrence bridge still need compilation and integration testing against your installed language bundles. Examples are not a claim that the full pipeline has been validated.

## Quick reference

| Type    | Annotation     | Where to use it | Purpose                                                   |
| --------| -------------- | --------------- | --------------------------------------------------------- |
| UI      | `@Model`       | Record          | Optional model marker                                     |
|         | `@F`           | Field           | General field settings, defaults, and validation metadata |
|         | `@L`           | List field      | List presentation and collection settings                 |
|         | `@FileSelector`| String field    | File-selection settings                                   |
|         | `@Ref`         | String field    | Reference to another item                                 |
|         | `@RefList`     | List of strings | References to multiple items                              |
|         | `@Template`    | String field    | Template-selection or generation settings                 |
| Summary | `@SchemaTitle` | Field           | Summary title                                             |
|         | `@SchemaField` | Field           | Value shown on a summary line                             |
|         | `@SchemaFlag`  | Field           | Flag path and display text                                |
|         | `@SchemaCount` | Field           | Collection path to count                                  |

The generated Python imports runtime modules rather than copying their public names into the generated module:

```python
import builtins as _types_builtins
import enum as _types_enum
import typing as _types_typing
import pydantic as _types_pydantic
from . import ui_api as _types_ui_api
from . import model_utils as _types_model_utils
```

Generated references are package-qualified, for example `_types_ui_api.F(...)`, `_types_ui_api.Model`, `_types_enum.StrEnum`, `_types_typing.Annotated`, `_types_pydantic.Field(...)`, and `_types_model_utils.list_templates()`. This lets declarations use names such as `F`, `Model`, `StrEnum`, `Field`, `Annotated`, `list`, or `dict` without colliding with imported names.

Python language keywords are still invalid declaration, field, and enum-member names. For example, `class`, `from`, and `lambda` cannot be made legal by qualification: `class class(...)` is invalid Python, and Python also rejects keyword attribute syntax such as `value.class`. The source grammar may impose additional reserved words before generation.

Summary annotations do not introduce another Python helper or import. They produce data in `MODEL_SUMMARIES`.

## Writing annotation arguments

Use named arguments to keep models readable:

```text
@F(default=3, required=true, label="Retry count")
int retries
```

Annotation values are limited to **strings, integers, floating-point numbers, and booleans**:

```text
@F(default="Task1")
string name

@F(default=3)
int retries

@F(default=0.5)
real threshold

@F(default=true)
bool enabled
```

Use `true` and `false` in the types file. The generator converts them to Python `True` and `False`.

Do not put a list, dictionary, lambda, or Python expression directly in an annotation argument. A string containing code remains a string; it is not executed.

### Empty annotations

Bare annotations have no arguments:

```text
@SchemaTitle
string name

@FileSelector
string report_file
```

The occurrence-aware implementation recognizes their presence even when their argument maps are empty.

Prefer the bare spelling shown above. Whether `@SchemaTitle()` is legal depends on the installed grammar; generator code cannot make a syntax form legal if the parser rejects it.

An empty annotation is different from an explicitly blank argument. For example, `@SchemaField` uses defaults, but `@SchemaField(label="")` is rejected.

### Repeated annotations

Summary annotations may repeat on one field:

```text
@SchemaField(label="Execution", subfield="engine")
@SchemaField(label="Execution", subfield="mode")
ExecutionSettings execution
```

Use the same annotation name each time.

UI helper annotations are different. 
A field can have only one of `F`, `L`, `FileSelector`, `Ref`, `RefList`, or `Template`. 
Combining `@F` and `@FileSelector` on the same field is an error. 
Put the needed UI arguments on the chosen helper instead.

## UI annotations

UI argument maps are forwarded to the selected package-qualified `_types_ui_api` helper after normalization. 
The examples below show the conventions used by this project, **not a guarantee that every argument is implemented by every version of your UI runtime**.

### `@Model`: mark a record

```text
@Model
record Task {
    string name
}
```

This is an optional marker, not a field helper. It does not create a summary by itself. Record generation does not depend on its presence. Parameterized `@Model` configuration is not implemented by the current generator; do not use it to configure fields or summaries.

### `@F`: configure a general field

```text
@F(default="Task1", label="Task name", required=true)
string name

@F(default=2, ge=1, le=50)
int batch_size

@F(default="Task1", pattern="^[A-Za-z][^ ]*$")
string identifier
```

Common arguments include:

| Argument | Intended use |
| --- | --- |
| `default` | Initial scalar value |
| `required` | Required-field metadata; without an explicit default, emits Python ellipsis |
| `label` | Human-readable field label |
| `help` | Help text |
| `ge`, `le` | Inclusive numeric lower and upper bounds |
| `pattern` | String-pattern constraint |
| `default_factory` | Named factory emitted as a lazy Python call |

The renderer rejects `ge > le` and simultaneous `default` and `default_factory`. Validation at model creation depends on the actual `F` implementation accepting and enforcing the constraints.

An explicit default is preserved even when `required=true`. The generator does not replace that default with ellipsis.

### `@L`: configure a list

```text
@L(title="Tasks", item_label="Task", presentation="map_detail", order=20)
Task[] tasks
```

Examples of forwarded settings include `title`, `item_label`, `presentation`, `order`, `import_export`, and `reverse_display`. Their UI effects depend on your runtime.

`@L` requires a list type. List defaults and list editing behavior are delegated to `L`; the generator does not implement a list editor.

### `@FileSelector`: choose a file

```text
@FileSelector(file_filter="XML files (*.xml);;All files (*)", required=true)
string configuration_file
```

Use it on a string field. The selected file is represented by that field's string value according to the UI runtime's contract.

For a list of file inputs, use `@L` with structured `items` metadata, as shown later, rather than putting `@FileSelector` on a list.

### `@Ref`: select one referenced item

```text
@Ref(path="/resources", value_field="resource_id", required=true)
string assigned_resource
```

- `path` identifies the collection in the runtime's reference-navigation scheme.
- `value_field` identifies the value stored for the selected item.
- `filters` can narrow the choices when supported by the runtime.

`@Ref` requires a string field and a nonblank `path`. A bare `@Ref` is recognized, but generation fails because the required path is missing.

The reference path is passed as the first positional argument of the Python `Ref(...)` call.

### `@RefList`: select several referenced items

```text
@RefList(path="/tasks", value_field="task_name", item_label="Task")
string[] dependencies
```

`@RefList` requires a list of strings and a nonblank `path`. It is not a list of embedded model objects.

Reference paths such as `/tasks` are different from summary subfields such as `execution.mode`: they are interpreted by different parts of the runtime.

### `@Template`: configure a template field

```text
@Template(generator="task_configuration", file_filter="XML files (*.xml)", advanced=true)
string configuration_template
```

Use it on a string field. Examples of forwarded arguments include `generator`, `predefined`, `file_filter`, and `advanced`.

A generator identifier such as `task_configuration` must be registered in the actual template runtime before it can be executed. Writing the annotation does not implement or register that generator.

## Structured UI metadata with `_json`

Some UI settings need a dictionary or list, but annotation arguments are scalar-only. For these UI settings, put JSON in a string and append `_json` to the argument name:

```text
@Ref(path="/resources", value_field="resource_id", filters_json="{\"resource_type\":\"WORKER\"}")
string assigned_resource

@F(default=2, relevant_if_json="{\"./enabled\":true}")
int batch_size

@L(title="Input files", items_json="{\"kind\":\"file_selector\",\"file_filter\":\"All files (*)\",\"required\":true}")
string[] input_files

@Template(generator="task_configuration", predefined_json="[]")
string configuration_template
```

At generation time, the generator:

1. Reads the string using the existing annotation utility.
2. Parses it as JSON.
3. Removes the `_json` suffix from the argument name.
4. Emits a native Python literal.

For example, `filters_json` becomes `filters={"resource_type": "WORKER"}`. No runtime JSON parser or `eval` is emitted.

The renderer checks that `filters`, `items`, `relevant_if`, and `required_if` are objects, and that `predefined` is a list. Invalid JSON and duplicate normalized arguments are rejected. Do not specify both `default` and `default_json` on the same annotation.

### Optional values and factories

```text
@F(default_json="null")
string optional_note
```

This emits a nullable Python annotation and a `None` default.

```text
@F(default_factory="dict")
map<string,string> properties
```

Named factories are limited by the renderer to `list`, `dict`, or declared type names. The renderer emits a lazy call such as `lambda: dict()`. It does not accept arbitrary factory expressions, and not every declared type is necessarily a useful zero-argument factory.

> Summary annotations do not use `_json`. Their small string arguments are designed to avoid structured annotation values entirely.

## Summary annotations

Summary annotations decide what appears in the generated `MODEL_SUMMARIES` dictionary. They do not change the model's field type, validation, or UI helper selection.

### `@SchemaTitle`: choose a title

```text
@SchemaTitle
string task_name
```

A nested title uses `subfield`:

```text
@SchemaTitle(subfield="identity.code")
TaskDetails details
```

This produces a title path of `details.identity.code`.

Supported argument: `subfield`.

A title is optional. A record with only a title gets a summary with an empty `lines` list. Identical repeated title annotations are harmless, but two different title paths in the same record are rejected.

### `@SchemaField`: show values on a line

```text
@SchemaField(label="Platform")
string platform

@SchemaField(label="Platform")
string variant
```

Both fields share one line:

```python
{"label": "Platform", "fields": ["platform", "variant"]}
```

Supported arguments: `label`, `subfield`.

With no arguments, the label and path default to the owning field name.

Repeat the annotation to display multiple subfields:

```text
@SchemaField(label="Execution", subfield="engine")
@SchemaField(label="Execution", subfield="mode")
ExecutionSettings execution
```

This produces:

```python
{"label": "Execution", "fields": ["execution.engine", "execution.mode"]}
```

The same path may appear on different labeled lines. Identical path/label contributions are deduplicated.

### `@SchemaFlag`: show short status text

```text
@SchemaFlag(label="Status", text="Enabled")
bool enabled
```

This produces:

```python
{"label": "Status", "flags": [{"path": "enabled", "text": "Enabled"}]}
```

Supported arguments: `label`, `subfield`, `text`.

Defaults:

- `label`: the owning field name.
- `path`: the owning field, optionally followed by `subfield`.
- `text`: the final component of that effective path.

For example:

```text
@SchemaFlag(subfield="policy.enabled")
ExecutionSettings execution
```

The label is `execution`, the path is `execution.policy.enabled`, and the text is `enabled`.

Multiple flags with the same label share one `flags` list. The same path/label cannot have conflicting text. Actual flag visibility is implemented by the UI runtime; the generator only emits the path and text.

### `@SchemaCount`: count a collection

```text
@SchemaCount(label="Tasks")
Task[] tasks
```

This produces:

```python
{"label": "Tasks", "count": "tasks"}
```

Supported arguments: `label`, `subfield`.

For a nested collection:

```text
@SchemaCount(label="Warnings", subfield="statistics.warnings")
TaskDetails details
```

The count path becomes `details.statistics.warnings`.

With no arguments, the label and count path default to the owning field name. The target should be a collection. The current summary builder checks path spelling, not whether the target actually has a collection type.

## Combining summary annotations

### Title and displayed field

```text
@SchemaTitle
@SchemaField(label="Identity")
string identifier
```

The same field can provide the title and appear on a line.

### Field and flag on the same line

```text
@SchemaField(label="Status")
@SchemaFlag(label="Status", text="Enabled")
bool enabled
```

This produces one line containing both `fields` and `flags`.

### Summary plus UI configuration

```text
@SchemaField(label="Execution")
@F(default=2, ge=1, le=50)
int batch_size
```

`@F` controls the generated field. `@SchemaField` controls the summary. Summary arguments are never forwarded to `F`.

### Combinations to avoid

These are rejected:

- Two distinct title paths in one record.
- A count sharing its label with fields or flags.
- Two different count paths sharing one label.
- The same flag path and label with different text.
- Unknown summary arguments, such as `isTitle` or `fields_json`.
- Blank labels/text or invalid subfields such as `a..b`, `a[0]`, or `a()`.
- More than one UI helper annotation on a field.

Exact repeated entries are idempotent. They do not create duplicate fields, flags, or count entries.

## How summary paths and ordering work

`subfield` is always **relative to the annotated field**:

```text
@SchemaField(label="Identity", subfield="display_name")
Identity identity
```

The result is `identity.display_name`. Do not write `identity.display_name` as the subfield unless you really want `identity.identity.display_name`.

Paths use dot-separated attribute names. They are not Python expressions and cannot contain calls, indexing, or slash navigation.

The builder currently validates path syntax only. It does not prove that nested attributes exist or that flag/count targets have the expected types. Keep the paths aligned with the actual model.

Within each record:

1. Fields are visited in declaration order.
2. Annotations on a field are visited in their original order.
3. The first encounter of a label determines its line position.
4. Later entries with that label are added to the same line.

Labels are exact and case-sensitive: `Status` and `status` are different lines. Grouping never crosses record boundaries.

## What if I use no annotations?

This is valid input for the generator's ordinary record handling:

```text
record PlainNote {
    string author
    string message
    bool archived
}
```

The record still becomes a Python `Model` subclass. Ordinary scalar fields use `F`, and list fields use `L` unless an explicit helper selects another supported behavior.

For an `F` field without explicit default/factory settings, the renderer normally uses:

| Type | Generated default behavior |
| --- | --- |
| `string` | Empty string |
| `int` | `0` |
| `real` | `0.0` |
| `bool` | `False` |
| Nested record | Lazy default factory for that record |
| Other non-primitive scalar type | Ellipsis unless configured explicitly |

`required=true` without an explicit default takes precedence and emits ellipsis. Recursive automatic record factories are rejected; break the recursion with an explicit nullable default or another suitable model design.

No effective summary annotations means no entry for that record in `MODEL_SUMMARIES`. This also applies to records with only `@Model` or only UI annotations. If no record has a summary, the generated module contains:

```python
MODEL_SUMMARIES = {}
```

A parent does not inherit its nested record's summary. Annotate the parent's fields explicitly if you want parent-level summary lines.

## A complete small example

```text
record ExecutionSettings {
    string engine
    string mode
    bool enabled
    string[] warnings
}

@Model
record Task {
    @SchemaTitle
    @F(default="Task1", required=true)
    string task_name

    @SchemaField(label="Execution", subfield="engine")
    @SchemaField(label="Execution", subfield="mode")
    @SchemaFlag(label="Status", subfield="enabled", text="Enabled")
    @SchemaCount(label="Warnings", subfield="warnings")
    ExecutionSettings execution

    // This field is deliberately not part of the summary.
    string internal_comment
}
```

The summary portion of the generated Python is equivalent to:

```python
MODEL_SUMMARIES = {
    Task: {
        "title": "task_name",
        "lines": [
            {"label": "Execution", "fields": ["execution.engine", "execution.mode"]},
            {"label": "Status", "flags": [{"path": "execution.enabled", "text": "Enabled"}]},
            {"label": "Warnings", "count": "execution.warnings"},
        ],
    },
}
```

Notice that `Task` is a class-object key, not the string `"Task"`. The dictionary is emitted after the classes have been declared.

## Generate and use the Python module

Run `TypesToPythonCli` using your existing Eclipse launch configuration or a classpath containing the language bundles. Its two arguments are the input types file and output Python file:

```text
"C:\path\to\schema_annotations_showcase.types" "C:\path\to\generated_package\models.py"
```

Absolute paths avoid confusion about the Java application's working directory.

Put the generated module in a Python package beside the actual `ui_api.py` and an `__init__.py`. Import it as a package module because `.ui_api` is a relative import. The generated module uses `_types_enum.StrEnum`, so use Python 3.11 or later.

The CLI does not supply the UI runtime, register template generators, or build an application around the models. Those remain part of the host project.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Input file not found | Resolve the input against the Java working directory, or use an absolute path. |
| Repeated or empty annotations disappear | Use the occurrence-aware implementation, not a name-to-map lookup alone. |
| Annotation occurrence bridge fails | Check the actual Common Lang annotation containment and name representation. |
| Missing summary entry | Add at least one effective summary annotation; `@Model` alone is not enough. |
| Unexpected grouping | Labels must match exactly, including case and spaces. |
| Count conflict | Give each distinct count its own label and do not mix it with fields/flags. |
| Reference generation fails | `Ref`/`RefList` need a nonblank path and the correct string/list-of-string type. |
| UI helper rejects an argument | Check your actual `.ui_api` signature and supported metadata. |
| Template cannot run | Register the annotation's generator identifier in the template runtime. |
| Invalid JSON | Escape quotes inside the types string and provide a valid JSON value. |
| Relative Python import fails | Import the generated module through its package, not as a standalone script. |
| Duplicate Java class | Remove old active Java implementations when replacing them with Xtend sources. |

## Implementation notes and current limits

- The generator traverses typed model declarations and fields.
- Repeated/empty annotation handling uses `AnnotationOccurrences` to preserve each occurrence, then delegates value decoding to the existing `AnnotationUtil` on an isolated copy.
- The original parsed model is not modified by occurrence isolation.
- Because the supplied archive does not include the generated Common Lang annotation interfaces, the occurrence bridge uses a small EMF metadata boundary. It assumes a direct many-valued annotation containment and scalar string annotation names. Different metamodel layouts need an adapted bridge.
- The renderer uses Xtend rich strings and the existing `Schema` intermediate representation.
- Summary grouping is implemented in `ModelSummaryBuilder` and emitted as declaration metadata, separate from UI field metadata.
- Type spelling still uses parsed type nodes. Synthetic models without those nodes are not equivalent to parsed input for this generator.
- Supported type spellings include `string`, `int`, `real`, `bool`, named types, `T[]`, and `map<K,V>` where accepted by the installed grammar.
- Unknown UI argument names are generally forwarded, not exhaustively validated. Summary argument names are validated strictly.
- The supplied renderer does not add `model_rebuild()` calls. Forward-reference resolution and model construction should be tested with the real runtime.
- No arbitrary expression-to-Python translation, custom validator generation, or automatic template-generator implementation is provided.
