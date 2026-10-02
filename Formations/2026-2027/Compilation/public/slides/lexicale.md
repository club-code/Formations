# Analyse lexicale

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

## Du texte aux tokens

<div class="pipeline">
<div class="stage">
Suite de caractères

```c
int main() {
int theo = 0;
for (int i  = 0; i < 5; i ++){
        theo ++;
    }
return theo;
}
```

</div>
<div class="arrow">→</div>
<div class="stage accent">
Lexer
</div>
<div class="arrow">→</div>
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
</div>

<p class="fragment">Pour l'ordinateur, le programme n'est qu'un long texte : il faut le découper en « mots ».</p>

---

## Les catégories de tokens

<table class="types">
<thead><tr><th>Catégorie</th><th>Exemples</th></tr></thead>
<tbody>
<tr><td>Mot-clé</td><td><code>int</code> <code>for</code> <code>return</code></td></tr>
<tr class="fragment"><td>Identifiant</td><td><code>main</code> <code>theo</code> <code>i</code></td></tr>
<tr class="fragment"><td>Littéral</td><td><code>0</code> <code>5</code></td></tr>
<tr class="fragment"><td>Opérateur</td><td><code>=</code> <code>&lt;</code> <code>++</code></td></tr>
<tr class="fragment"><td>Ponctuation</td><td><code>(</code> <code>)</code> <code>{</code> <code>}</code> <code>;</code></td></tr>
</tbody>
</table>

---

## Comment ça marche ?

<table class="types">
<thead><tr><th>Token</th><th>Expression régulière</th></tr></thead>
<tbody>
<tr><td>Identifiant</td><td><code>[a-zA-Z_][a-zA-Z0-9_]*</code></td></tr>
<tr class="fragment"><td>Nombre</td><td><code>[0-9]+</code></td></tr>
<tr class="fragment"><td>Opérateur</td><td><code>\+\+</code> &nbsp; <code>&lt;</code> &nbsp; <code>=</code></td></tr>
</tbody>
</table>

<p class="fragment">Chaque expression est compilée en <strong>automate fini</strong> : on lit les caractères un par un.</p>

<p class="small fragment">Règle du plus long préfixe : <code>++</code> est un seul token, pas deux <code>+</code></p>

---

## Ça compile ?

<div class="cols errors">
<div>

```c
    int 3theo = 0;
```

<p class="error">invalid suffix 'theo' on integer constant</p>

</div>
<div class="fragment">

```c
    return "theo;
```

<p class="error">missing terminating '"' character</p>

</div>
</div>

<p class="small fragment">Une erreur lexicale : un morceau de texte ne correspond à aucun token.</p>
