 ## **DLink Finder**

 Description
|                           ---                         |
|                                                       |
|   **Find and download dynamic files from web pages**  |
|                                                       |
|   Optionnal : call with arguments to replace the default config   |

--------------------

### Features ✨ 

- 🔍 Smart link detection
- 🌐 GitHub releases and repositories links support
- 🔄 Progress bar during downloads
- 🛡️ File integrity checks
- 🎯 Filtering
- 📊 File size display
- 🛠️ Callable with arguments, or preconfigured
- 🪜 Can pass other arguments to a downloaded executable

--------------------

### Arguments ⚙️

|  Argument  | Description                                    | Required |
|:----------:|------------------------------------------------|----------|
| **/url** (REQUIRED) | URL of the webpage to analyze         | Yes      |
| **/name**           | Name for console output               | No       |
| **/destination**    | File path destination                 | No       |
| **/include**        | Include links containing text         | No       |
| **/exclude**        | Exclude links containing text         | No       |
| **/extension**      | Include file extension                | No       |
| **/lucky (0 or 1)** | Auto select first result              | No       |
| **/arguments**      | Execute file downloaded with args.    | No       |

--------------------

### Examples 📝
`DLinkFinder /url https://example.com /extension exe /include x64`

To use with github releases, you have to specify "releases/latest" at the end of the link

`DLinkFinder /name "Git" /url https://github.com/git-for-windows/git/releases/latest`

--------------------

### When using /arguments 🔧
- If multiple arguments, don't forget to "" the full chain
- You have to use **+** to separate multiple arguments 
- Inside an argument you have to use `'` instead of `"`

```
DLink_Finder.bat ^
  /url https://example.com ^
  /extension msi ^
  /lucky 1 ^
  /arguments "/qn + TANSFORMS='C:\Users\My name\transform.mst' + /l*v + 'log.log'"
```

--------------------

- Requires PowerShell and administrative privileges for some operations
- Internet connection is required
- Many websites may block automated downloads. Feels free to make a pull request.
