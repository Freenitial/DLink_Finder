 ## **DLink Finder**

 Description
|                           ---                         |
|                                                       |
|   **Find and download dynamic files from web pages**  |
|                                                       |
|   Optionnal : call with arguments to replace the default config   |

--------------------

## Features ✨ 

- 🔍 Smart link detection
- 🌐 GitHub releases and repositories links support
- 📦 Multiple file format support
- 🔄 Progress bar during downloads
- 🛡️ File integrity checks
- 🎯 Filtering
- 📊 File size display

--------------------

## Usage 🚀 

```
DLink_Finder.bat [/name name] [/url url] [/pattern pattern] [/extension ext]
```

Parameters
|  Parameter | Description                           | Required |
|:----------:|---------------------------------------|----------|
| **/url**       | URL of the webpage to analyze         | Yes      |
| **/name**      | Name for console output               | No       |
| **/pattern**   | Include links containing text         | No       |
| **/exclude**   | Exclude links containing text         | No       |
| **/extension** | Include file extension                | No       |
| **/lucky**     | Auto select first result              | No       |

--------------------

## Examples 📝
`DLinkFinder /url https://example.com /extension exe /pattern x64`

To use with github releases, you have to specify "releases/latest" at the end of the link

`DLinkFinder /name "Git" /url https://github.com/git-for-windows/git/releases/latest`

--------------------

- Requires PowerShell and administrative privileges for some operations
- Internet connection is required
- Many websites may block automated downloads. Feels free to make a pull request.
