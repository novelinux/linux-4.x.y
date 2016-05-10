next_arg
========================================

```
/* You can use " around spaces, but can't escape ". */
/* Hyphens and underscores equivalent in parameter names. */
static char *next_arg(char *args, char **param, char **val)
{
    unsigned int i, equals = 0;
    int in_quote = 0, quoted = 0;
    char *next;

    if (*args == '"') {
        args++;
        in_quote = 1;
        quoted = 1;
    }

    for (i = 0; args[i]; i++) {
        if (isspace(args[i]) && !in_quote)
            break;
        if (equals == 0) {
            if (args[i] == '=')
                equals = i;
        }
        if (args[i] == '"')
            in_quote = !in_quote;
    }

    *param = args;
    if (!equals)
        *val = NULL;
    else {
        args[equals] = '\0';
        *val = args + equals + 1;

        /* Don't include quotes in value. */
        if (**val == '"') {
            (*val)++;
            if (args[i-1] == '"')
                args[i-1] = '\0';
        }
        if (quoted && args[i-1] == '"')
            args[i-1] = '\0';
    }

    if (args[i]) {
        args[i] = '\0';
        next = args + i + 1;
    } else
        next = args + i;

    /* Chew up trailing spaces. */
    return skip_spaces(next);
}
```