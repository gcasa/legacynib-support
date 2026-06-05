# Legacy OPENSTEP Nib Support for GNUstep

This repository is an investigation workspace for loading or converting
OPENSTEP 4.2 typed-stream nibs for use with GNUstep.

## Current conclusion

Support appears possible, but it is not a small extension to GNUstep's current
`GSNibLoader`.

OPENSTEP 4.2 nibs are typed-stream archives. GNUstep's current nib loader
expects a Cocoa keyed archive (`bplist00` or an archive containing
`NSKeyedArchiver`). The historical `nib2gmodel` converter avoided parsing the
typed stream itself: it ran on OPENSTEP or early macOS, asked the native AppKit
to load the nib, observed the resulting object graph, and wrote a GNUstep
gmodel file.

There are therefore two viable approaches:

1. **Conversion on OPENSTEP 4.2**: revive `nib2gmodel`, convert nibs to gmodel,
   then open and resave them with Gorm. This is the shortest path for a finite
   collection of nibs.
2. **Native GNUstep importer**: implement enough of the legacy typed-stream
   decoder and OPENSTEP AppKit class decoding behavior to convert old nibs on a
   modern system. This is the path required for general GNUstep support.

Do not begin by adding typed-stream logic directly to `GSNibLoader`. Build a
standalone converter first. Once it handles a useful fixture corpus, its
decoder can be integrated as another `GSModelLoader` or retained as an import
tool.

## Start here

### 1. Build a legal test corpus

Put representative nibs under `fixtures/nibs/`. Start with nibs you created or
have permission to redistribute.

The minimum useful corpus is:

- An empty application nib
- One window containing common controls
- A main menu
- Outlets and action connections
- Custom classes
- Images, colors, fonts, and attributed text
- Nibs from both OPENSTEP 4.2/m68k and OPENSTEP 4.2/x86, if available

Keep the source project and screenshots alongside each nib. They provide the
expected result when automated decoding is incomplete.

### 2. Inventory every sample

Run:

```sh
./tools/inspect-nib.sh fixtures/nibs/MyInterface.nib
```

Commit the generated report under `fixtures/reports/`. Compare directory
layout, file headers, embedded class names, and architecture differences before
writing a decoder.

### 3. Establish the conversion baseline

In an OPENSTEP 4.2 virtual machine:

```sh
./configure
gnumake
gnumake install
nib2gmodel MyInterface.nib MyInterface.gmodel
```

Use the historical source at
<https://github.com/gnustep/tools-model-main>. The converter must run while
logged into an OPENSTEP graphical session because it uses native AppKit to load
the nib.

Save the converted gmodel and any converter logs next to each test fixture.
This gives a reference object graph for a future native decoder.

### 4. Prototype a standalone native importer

The first native prototype should only:

1. Locate `objects.nib` within a legacy nib package.
2. Recognize the typed-stream variant and byte order.
3. Enumerate archived class names, class versions, and object references.
4. Emit a neutral diagnostic representation without instantiating AppKit
   objects.

Only after this works across the fixture corpus should the importer map archive
records to GNUstep objects or gmodel records.

## Suggested architecture

Keep the format parser independent from AppKit:

```text
legacy typed stream
        |
        v
archive records: classes, objects, values, references
        |
        v
OPENSTEP nib semantic model: objects, names, classes, connections
        |
        +--> diagnostic JSON
        +--> GNUstep gmodel/gorm conversion
        +--> optional GSModelLoader integration
```

This separation matters because old nibs encode implementation details of
individual AppKit classes. A correct typed-stream parser alone will not be
enough; class-version-specific decoding and compatibility shims will also be
needed.

## Upstream code to study

- GNUstep keyed nib loader:
  <https://github.com/gnustep/libs-gui/blob/master/Source/GSNibLoader.m>
- GNUstep model loader factory:
  <https://github.com/gnustep/libs-gui/blob/master/Source/GSModelLoaderFactory.m>
- GNUstep gmodel loader:
  <https://github.com/gnustep/libs-gui/blob/master/Source/GSGModelLoader.m>
- Historical nib-to-gmodel translator:
  <https://github.com/gnustep/libs-gui/blob/master/Model/Translator.m>
- Standalone historical nib2gmodel package:
  <https://github.com/gnustep/tools-model-main>

## Initial success criteria

The investigation has cleared its first feasibility gate when a modern,
standalone tool can inspect several OPENSTEP 4.2 nibs and reproduce:

- Archived class names and versions
- Object identity and references
- Top-level objects
- Outlet and action connections
- Basic geometry and common control attributes

Pixel-perfect rendering is not required at this stage.

