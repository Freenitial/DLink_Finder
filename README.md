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

|  Argument  | Description                                    |
|:----------:|------------------------------------------------|
| **/url** (REQUIRED) | URL of the webpage to analyze         |
| **/name**           | Name for console output               |
| **/destination**    | File path destination                 |
| **/include**        | Include links containing text         |
| **/exclude**        | Exclude links containing text         |
| **/extension**      | Include file extension                |
| **/lucky (0 or 1)** | Auto select first result              |
| **/arguments**      | Execute file downloaded with args.    |

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
