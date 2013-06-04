feck - An interpreted language written in Ruby
==============================================

Author: Anthony Burzillo

******

## Language

feck is a dynamically-typed, interpreted language. Some examples of feck features
include parallel assignment and boolean operators with precedence.

```shell
$ cat > test.fck
a, b, c = 5, "Hello, there"
puts a, b, c
$ ./feck test.fck
5
Hello, there
nil
```

```shell
$ cat > test.fck
x = 5
if x < 4
  puts 1
elif true || false and true && false
  puts 2
else
  puts 3 * 2.5
end
$ ./feck test.fck
7.5
```

To see the most current possibilites in feck, see its grammar in EBNF for in
feck_grammar.txt

## Execuatables

Example program:

```shell
$ cat > test.fck
puts true and
false
```

See test_programs/ for more examples.

### feck


Print out the tokens of the program:

```shell
$ ./feck -l
puts@1 | true@1 | and@1 | false@2
```

Create a representation of the symbol table of the program (with [dot] installed):

[dot]: http://www.graphviz.org/

```shell
$ ./feck -t test.fck | dot -T jpeg > table.jpg
```

Create a representation of the abstract syntax tree of the program (with [dot] installed):

```shell
$ ./feck -a test.fck | dot -T jpeg > tree.jpg
```

Run a program:

```shell
$ ./feck test.fck
false
```

### ifk - an interactive interpreter

Example usage (quit with ctrl-d):

```shell
$ ./ifk
ifk:1  > puts true and
ifk:2 ?> false
false
=> false
```

The value following the '=>' is the result of the last expression evaluated.

### pics

Creates the symbol table and abstract syntax tree

```shell
$ ./pics test.fck
```

### all

Run all four options of feck in order

```shell
$ ./all test.fck
puts@1 | true@1 | and@1 | false@2
======OUTPUT======
false
```

## License

The MIT License (MIT)

Copyright (c) 2013 Anthony Burzillo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

