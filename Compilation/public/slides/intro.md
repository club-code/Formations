# Introduction

---

## C'est quoi un compilateur ?

<div class="pipeline">
<div class="stage">
Code source<br><code>main.c</code>
</div>
<div class="arrow">→</div>
<div class="stage accent">
Compilateur<br><code>clang</code>
</div>
<div class="arrow">→</div>
<div class="stage">
Exécutable<br><code>a.out</code>
</div>
</div>

<p class="fragment">Un traducteur : un langage lisible par l'humain → du code lisible par la machine</p>

---

## Compilé ou interprété ?

| | Compilé | Interprété |
|---|---|---|
| Exemples | C, C++, Rust, Go | Python, Ruby, JavaScript |
| Traduction | une fois, **avant** l'exécution | pendant l'exécution |
| Erreurs détectées | à la compilation | à l'exécution |
| Vitesse | rapide | plus lente |


---

## Notre fil rouge

```c
int main() {
    int theo = 0;
    for (int i  = 0; i < 5; i ++){
        theo ++;
    }
    return theo;
}
```

<p class="fragment">Comment passe-t-on de ces quelques lignes à des instructions machine ?</p>

---

## Les phases de la compilation

<div class="pipeline">
<div class="stage">Lexical</div>
<div class="arrow">→</div>
<div class="stage">Syntaxique</div>
<div class="arrow">→</div>
<div class="stage">Sémantique</div>
</div>

<div class="pipeline fragment">
<div class="stage">IR</div>
<div class="arrow">→</div>
<div class="stage">Optimisations</div>
<div class="arrow">→</div>
<div class="stage">Code machine</div>
</div>

---

## Entrée → sortie

<table class="small">
<thead><tr><th>Phase</th><th>Entrée</th><th>Sortie</th></tr></thead>
<tbody>
<tr><td>Lexical</td><td>caractères</td><td>tokens</td></tr>
<tr><td>Syntaxique</td><td>tokens</td><td>AST</td></tr>
<tr><td>Sémantique</td><td>AST</td><td>AST vérifié</td></tr>
<tr><td>IR</td><td>AST</td><td>LLVM IR</td></tr>
<tr><td>Optimisations</td><td>IR</td><td>IR simplifié</td></tr>
<tr><td>Code machine</td><td>IR</td><td>x86, ARM…</td></tr>
</tbody>
</table>
