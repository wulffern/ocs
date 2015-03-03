# ocs (Alpha 0.1)
Virtuoso ocean script support package.

## Introduction
Some love the SKILL language (a LISP variant), but I'm not one of them. There are too many parentheses, especially when writing extractions in ocean. I wanted something cleaner in my testbenchs, so I wrote a wrapper around ocean. It basically
- Preprocess some directives (#include, #expr, #define etc)
- Set which corners to run
- Redefine the output ADE-XL view based on view and defines
- Creates a ocean compatible script
- Run ocean
- Extracts simulation values from log file into a csv file.

For example:
```
oc ocean tran --corners "typical" --config "" --define "" --run
```


##Warning
Be warned, the script is undocumented, and probably quite hard to use unless you speak Perl. Things may also change without notice, so don't come crying if your testbenches suddenly stop working.

