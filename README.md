 ## **DLink Finder**

Description
|                           ---                            |
|                                                       |
|   **Find and download dynamic files from web pages**   |
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
CopyDLinkFinder [/name name] [/url url] [/pattern pattern] [/extension ext]
```

Parameters
|  Parameter | Description                           | Required |
|:----------:|---------------------------------------|----------|
| **/name**      | Name for console output               | No       |
| **/url**       | URL of the webpage to analyze         | Yes      |
| **/pattern**   | Text to search in found links | No       |
| **/extension** | File extension to search for          | No       |

--------------------

## Examples 📝
`DLinkFinder /url https://example.com /extension exe /pattern x64`

To use with github releases, you have to specify "releases/latest" at the end of the link

`DLinkFinder /name "Git" /url https://github.com/git-for-windows/git/releases/latest`

--------------------

- Requires PowerShell and administrative privileges for some operations
- Internet connection is required
- Many websites may block automated downloads. Feels free to make a pull request.
