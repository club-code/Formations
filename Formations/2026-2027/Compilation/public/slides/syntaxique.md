# Analyse syntaxique

```c
int main() {
    int theo = 0;
    for (int i  = 0; i < 5; i ++){
        theo ++;
    }
    return theo;
}
```

---

<!-- .slide: class="tiny-code" -->

## Des tokens à la structure

<div class="pipeline">
<div class="stage">
Suite de tokens

```plaintext
[int] [main] [(] [)] [{]
[int] [theo] [=] [0] [;]
[for] [(] [int] [i] [=] [0] [;]
[i] [<] [5] [;] [i] [++] [)] [{]
[theo] [++] [;]
[}]
[return] [theo] [;]
[}]
```

</div>
<div class="arrow">→</div>
<div class="stage accent">
Parser
</div>
<div class="arrow">→</div>
<div class="stage">
Arbre

```plaintext
function main
`-block
  |-decl theo = 0
  |-for
  | |-decl i = 0
  | |-i < 5
  | |-i++
  | `-block
  |   `-theo++
  `-return theo
```

</div>
</div>

<p class="fragment">Les tokens sont en ligne, mais le programme est <strong>imbriqué</strong> : une fonction contient un bloc, qui contient une boucle…</p>

<p class="small fragment">Le parser vérifie que les tokens respectent la <strong>grammaire</strong> du langage.</p>

---

<!-- .slide: class="small-code" -->

## Une grammaire (BNF)

<div class="cols">
<div class="grow">

```plaintext [|1|2|3-4|5|6|7-9]
function ::= type IDENT "(" ")" block
block    ::= "{" stmt* "}"
stmt     ::= decl | for | return | expr ";"
decl     ::= type IDENT "=" expr ";"
for      ::= "for" "(" decl expr ";" expr ")" block
return   ::= "return" expr ";"
expr     ::= cmp
cmp      ::= post "<" post | post
post     ::= primary "++" | primary
primary  ::= IDENT | NUMBER
```

</div>
<div class="small">

- `::=` : « se compose de »
- `|` : ou
- `*` : zéro ou plus
- `"for"`, `"("` : tokens
- `IDENT`, `NUMBER` : catégories du lexer

</div>
</div>

---

<!-- .slide: class="small-code" -->

## L'arbre de dérivation

<p class="desc">On applique les règles pour retrouver <code>i &lt; 5</code></p>

```plaintext [|1-2|3-6|7-10]
expr
`-cmp
  |-post
  | `-primary
  |   `-IDENT i
  |-"<"
  `-post
    `-primary
      `-NUMBER 5
```

---

<!-- .slide: class="small-code" -->

## De l'arbre de dérivation à l'AST

<div class="cols">
<div class="grow">

<p class="small">Arbre de dérivation</p>

```plaintext
expr
`-cmp
  |-post
  | `-primary
  |   `-IDENT i
  |-"<"
  `-post
    `-primary
      `-NUMBER 5
```

</div>
<div >

<p class="small">AST</p>

```plaintext
BinaryOperator '<'
|-DeclRefExpr i
`-IntegerLiteral 5
```

</div>
</div>

<p class="small fragment">L'AST garde l'essentiel : plus de règles intermédiaires ni de ponctuation.</p>

---

## Ça compile ?

<div class="rows errors">
<div>

```c
  for (int i = 0; i < 5 i ++){
```

<p class="error">expected ';' in 'for' statement specifier</p>

</div>
<div class="fragment">

```c
  theo ++
```

<p class="error">expected ';' after expression</p>

</div>

</div>

