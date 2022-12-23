```@meta
CurrentModule = ODMXMLTools
```

# ODMXMLTools

ODMXMLTools.jl is a simple tool set for working with ODM-XML.

[ODM-XML](https://www.cdisc.org/standards/data-exchange/odm) is a vendor-neutral, platform-independent format for exchanging and archiving clinical and translational research data, along with their associated metadata, administrative data, reference data, and audit information. ODM-XML facilitates the regulatory-compliant acquisition, archival and exchange of metadata and data. It has become the language of choice for representing case report form content in many electronic data capture (EDC) tools.

The ODM has been designed to be compliant with guidance and regulations published by the FDA for computer systems used in clinical studies.

See [CDISK](https://www.cdisc.org/) site for more information.

This program comes with absolutely no warranty. No liability is accepted for any loss and risk to public health resulting from use of this software.

# Install

```
import Pkg; Pkg.add(url="https://github.com/PharmCat/ODMXMLTools.jl.git")
```

Or from registry:

```
import Pkg; Pkg.add("ODMXMLTools")
```

## Contents

```@contents
Pages = [
        "index.md",
        "api.md"
      ]
Depth = 3
```
