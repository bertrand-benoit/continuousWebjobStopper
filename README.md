# Azure continuous webjob lister/stopper version 2.2.0

This is a free tool allowing to automatically list/stop all/specified continuous webjob(s) of specified Azure Webapp.

This script uses my [scripts-common](https://github.com/bertrand-benoit/scripts-common) project, you can find on GitHub.

## Requirements
This tool used:
-   [jq](https://stedolan.github.io/jq/) which must be priorly installed. It is generally available with your package manager.
-   [az](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) the Azure CLI v2 which must be priorly installed.

Ensure you logged in with Azure CLI v2:
```bash
az login
```

And select the subscription you want to work on:
```bash
az account list --out table
az account set --subscription xxxxxxxxxx
```

## First time you clone this repository
After the first time you clone this repository, you need to initialize git submodule:
```bash
git submodule init
git submodule update
```

This way, [scripts-common](https://github.com/bertrand-benoit/scripts-common) project will be available and you can use this tool.

## Configuration files
This tools uses the configuration file feature of the [scripts-common](https://github.com/bertrand-benoit/scripts-common) project.

The global configuration file, called **default.conf**, is in the root directory of this repository.
It contains default configuration for this tool, and should NOT be edited.

You can/should create your own configuration file **~/.config/stopContinuousJob.conf** and override any value you want to adapt to your needs.

By default (without --resourceGroup option), script will lookup for resource group owning the specified webapp.
To do so, it uses your **patterns.removeMatchingParts** configuration to "extract" part common to webapp name and resource group name.

### User configuration file sample
For instance:
-   let's call your webapp 'test-myVeryNiceWebApp-v3'
-   let's call the owning resource group 'NiceWebApp'

Then you can define **patterns.removeMatchingParts** in your configuration file **~/.config/stopContinuousJob.conf**:
```bash
# List of regular expressions of parts to remove from Website name,
#  to retrieve the corresponding resource group, separated by | character.
# These regular expressions are used with sed, with -E option,
#  and case insensitive.
# You can check the man of sed for more information about writing such expressions.
patterns.removeMatchingParts="^test-|myVery|-v[0-9]$"
```

In case, there is no common part at all, you can still use the **--resourceGroup** option to specify it.

## Usage
```bash
Usage: ./stopContinuousJob.sh -a|--webapp <webapp name> [-r|--resourceGroup <resource group>] [-w|--webjob <webjob name>] [--list] [--debug] [-h|--help]
<webapp name>	name of the webapp whose continuous job must be managed
<resource group>name of the resource group which owns the webapp to manage (default: automatically detected according to your configuration)
<webjob name>	name of the webjob to manage (default: ALL webjob of the specfified webapp)
--list		list continuous webjob instead of stopping them
--debug		show found episode number
-h|--help	show this help
```

## Samples
Stop all continuous webjobs of Webapp 'myWebApp' (with automatic resource group lookup):
```bash
  ./stopContinuousJob.sh -a 'myWebApp'
```

Stop all continuous webjobs of Webapp 'myWebApp', and resource group 'test-rg':
```bash
  ./stopContinuousJob.sh -a 'myWebApp' -r 'test-rg'
```

Stop the webjob 'myWebjob' of Webapp 'myWebApp', and resource group 'test-rg':
```bash
  ./stopContinuousJob.sh -a 'myWebApp' -r 'test-rg' -w 'myWebjob'
```

List all continuous webjobs of Webapp 'myClient1WebApp', and resource group 'prod-rg':
```bash
  ./stopContinuousJob.sh --list -a 'myClient1WebApp' -r 'prod-rg'
```


## Contributing
Don't hesitate to [contribute](https://opensource.guide/how-to-contribute/) or to contact me if you want to improve the project.
You can [report issues or request features](https://github.com/bertrand-benoit/continuousWebjobStopper/issues) and propose [pull requests](https://github.com/bertrand-benoit/continuousWebjobStopper/pulls).

## Versioning
The versioning scheme used in this project is [SemVer](http://semver.org/).

## Authors
[Bertrand BENOIT](mailto:contact@bertrand-benoit.net)

## License
This project is under the GPLv3 License - see the [LICENSE](LICENSE) file for details.
