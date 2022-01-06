# Posix Basics

*Note:* I will be using CentOS 9 Stream which came out in Dec 2021. I will not be covering UNIX OS.

We will dive in POSIX standardization, on the best practices for system interfaces, command interpreter and utilities. Our goal is to understand why POSIX exist, and how to apply their best practices.

## Definition

POSIX stands for *Portable Operating System Interface* and defines a set of standards to provide compatibility between different computing platforms.

The latest version is available [here](https://pubs.opengroup.org/onlinepubs/9699919799/toc.htm)

Not all operating systems are POSIX certified (such as _Solaris_ or _macOS_), but they can be fully or partly POSIX compatible, as such, most OS try to be mostly POSIX-compliant.

A few examples of POSIX-compliant:
- Android
- FreeBSD
- Linux
- VMWare ESXi
- Cygwin

When writing scripts/programs to rely on POSIX standards, you ensure to port them among a large family of Unix derivatives.

## Shell language

The shell is a command language interpreter, which includes a syntax used by the `sh` utility.

The difference between `#!/bin/bash` and `#!/bin/sh` is slim, as It spawns from the same binary:

![image](https://user-images.githubusercontent.com/72258375/148414947-202f59df-4b7a-460e-b64e-94a33888635a.png)

![image](https://user-images.githubusercontent.com/72258375/148415029-dd97433f-9246-4791-9382-28b1f7b6d908.png)

Using `sh` is simply having `bash` with [`--posix` option](https://tiswww.case.edu/php/chet/bash/POSIX) after startup files are read. These startup files are the ones read and executed from the expanded `ENV` variable. 

It is not the case on every OS though, `busybox` can link `sh` to a [different shell](https://en.wikipedia.org/wiki/Almquist_shell), but one common point they all have is having a `/bin/sh`. This is why in our case, It is better to use `sh` as a shell basis for our scripts.

## Variable expansion

It is possible to manipulate variable with prefix, suffix, default, fallback and message in portable shell syntax.

Consider this shell script:

![image](https://user-images.githubusercontent.com/72258375/148214028-2e3712f3-a582-4b0e-8d8d-0140668f2dbf.png)

It will print the variable value depending on its parameters

![image](https://user-images.githubusercontent.com/72258375/148214059-2da3bcc9-5ca7-425f-83bb-21235188ae1f.png)

While there is a few more, for example to search and replace, It is interesting to know It is POSIX compliant to do so.

Be careful with `unset` as It is not compliant on arrays (only variables and functions)

## Environment variables

Environment variables should always use UPPERCASE and underscore, like so:

![image](https://user-images.githubusercontent.com/72258375/148242733-4f51a291-0a29-46ac-9ddb-62097cb54185.png)

Only way to set an environment variable is through `export`, but they will only be available in the current session.

## Program exit status

Standard exit code is *0* for success, any number from *1* to *255* is to denote something else.

To access the last exit code, you can use `$?`

![image](https://user-images.githubusercontent.com/72258375/148244032-c1716bcd-47b9-4826-b6ff-312e5e88a08b.png)

It is possible to suppress the exit code by nullifying *STDERR* and adding an *OR*, but this is not recommended

![image](https://user-images.githubusercontent.com/72258375/148245258-d879e571-0e0d-48ad-a4e1-ecbea3dbf235.png)

## Command line utility API conventions

Standard POSIX utilities includes an argument syntax to help them process.

Unless otherwise noted, all utility descriptions use this notation, which is illustrated by this command:

![image](https://user-images.githubusercontent.com/72258375/148248585-5fa5b28b-43c0-4559-93f3-3cb34335699f.png)

The utility is always named first, then comes the option-arguments, and includes two optionals modes : short options (single `-`) and long options (double `--`).

In long options, parameters are added with `--long_option=<PARAMETER>`, while short options are one character-long and requires a <blank_space> between their parameters, e.g. `-s <PARAMETER>`.

Optional arguments are then followed by mandatory arguments (called **operands**). You can include `--` in-between to specify the ends of the optional-arguments, and helps in specific directory like *systemd*, where some filenames begin with `-`

A few guidelines (or design pattern) on these utilities: 
- Thou shalt not use more than nine characters or capital letters for their name
- Option-arguments should not be optional

While nothing is said about `-h` or `-v`, they are usually kept for *help* and *version* section.

## Filenames

Filenames cannot contain "/" nor ASCII NUL "\0". While this is flexible, a few more tiny limitations is necessary to be added upon the existing set of limitations.

The character `-` is one to look out for, as It can lead to disaster.

Let's create a file named `-rf`

![image](https://user-images.githubusercontent.com/72258375/148251686-acf8abc6-0296-4ca3-98ac-f5841e7fc2ca.png)

And see what happens when someone try to remove all files in the directory with `rm *`, It should not destroy directories right ?

![image](https://user-images.githubusercontent.com/72258375/148251832-c88f1b07-90d8-458e-9790-7c04a5c92983.png)

Well.. not only did It destroy the directory, It also kept the *-rf* file. This could lead to bigger disaster.

If you need to remove it, use `--`

![image](https://user-images.githubusercontent.com/72258375/148252083-b4712e27-af24-47e0-bfb5-8226b55d38ac.png)

There is many more examples, but this is the reason why you need to ensure your file names should not start with `-` or control chars (such as `\n\t`).

## Directory structure

Most linux distribution conform to **FHS** (Filesystem Hierarchy Standard), which defines a stricter set of rules to define the directory structure.

POSIX defines a few guidelines on this structure:
- Applications should not be writing files in `/` or `/dev`
- `/tmp` should be made available for applications in need of temporary files creation.
- `/dev/null` is an infinite data sink, data written to or reads from this path should always return *EOF*
- `/dev/tty` Synonym for controlling terminal associated with the process group of that process

## Regular expression

POSIX defines two regular expression syntax, called **BRE** (Basic) and **ERE** (Extended).

**BRE** provides extensions to achieve consistency between utility programs such as `grep` or `sed`.

In BRE, It defines the following syntax:

| Metacharacter | Description |
| --- | --- |
| `.` | Matches any single character |
| `[ ]` | Matches a single character that is contained within the brackets |
|  `[^ ]` | Matches a single character that is **not** contained within the brackets |
| `^` | Matches the starting position, if It is the first character of the regex |
| `$` | Matches the ending position, if It is the last character of the regex |
| `*` | Matches the preceding element zero or more times |
| `\{m\}` | Matches the preceding element exactly *m* times |
| `\( \)` | Defines a capturing group, and treated as a single element |

While defining character classes that are used **within brackets**

| POSIX class | similar to | meaning |
| --- | --- | --- |
| [:upper:] |	[A-Z] |	uppercase letters |
| [:lower:] |	[a-z] |	lowercase letters |
| [:alpha:] |	[A-Za-z] |	upper- and lowercase letters |
|[:digit:] | [0-9] |	digits |
| [:xdigit:] | [0-9A-Fa-f] |	hexadecimal digits |
| [:alnum:] |	[A-Za-z0-9] |	digits, upper- and lowercase letters |
| [:punct:] |	|	punctuation (all graphic characters except letters and digits) |
| [:blank:] |	[ \t] |	space and TAB characters only |
| [:space:] |	[ \t\n\r\f\v] |	blank (whitespace) characters | 

And the more advanced **extended** regular expressions can sometimes be used with Unix utilities (`grep -E`, `sed -E`, or default in `awk`), the main difference is that some backlashes are removed, and non-greedy quantifiers (?)

## Shell syntax

Let's use [`Shellcheck`](https://github.com/koalaman/shellcheck) and test some commands to see how to write POSIX compliant code. It assumes you are somewhat familiar with shell scripting.

The script:

![image](https://user-images.githubusercontent.com/72258375/148436205-c424f51b-eedd-402a-a5e2-407420338fc6.png)

The execution:

![image](https://user-images.githubusercontent.com/72258375/148436264-e913a984-adae-436a-8083-86dccea354f7.png)

Shellsheck:

![image](https://user-images.githubusercontent.com/72258375/148436321-0e81fee4-913c-4e9a-a0db-1c479beaf697.png)

In the end, some rules to remember are: 
- Use `test` or single bracket for comparison. Use gt/lt for numbers, and avoid strings comparison with `==`.
- Do not use arrays, and do not use `declare` `let` `typeset` or blank spaces when declaring variables
- Always quote strings, and use `printf` instead of `echo`

## Conclusion

While this ends POSIX basics, there is a lot to review in order to be POSIX compliant across all your shell scripts. The most difficult part is to know which tool is part of the core package, and which one requires an installation check.

A few tools exist to check your syntax, like `Checkbashims` or [`Shellcheck`](https://github.com/koalaman/shellcheck). One tool, not really POSIX related, is useful for checking your bash commands is [explainshell](https://explainshell.com)

![image](https://user-images.githubusercontent.com/72258375/148260361-be230fca-9fa6-4158-934a-0890c3389233.png)

Being POSIX compliant can be a pain (specially on grep, awk and sed implementations). It should serve as a common set of best practices for your scripts.


> Credits
>
> https://riptutorial.com/posix
>
> https://pubs.opengroup.org/onlinepubs/9699919799/toc.htm
>
> https://www.baeldung.com/linux/posix
>
> https://en.wikibooks.org/wiki/Regular_Expressions/POSIX-Extended_Regular_Expressions
>
> https://betterprogramming.pub/24-bashism-to-avoid-for-posix-compliant-shell-scripts-8e7c09e0f49a
>
>
