# Endering

Implementation of a dictionary-assisted suffix-stripping morphographemic analyser after (Winograd 1972).

This program will reduce a word to it's base "meaning" by stripping various suffixes and/or rewriting them based on a rudimentary ruleset of English grammar.

As such, it is not a generic stemmer. For example the word "ran" will remain as is. This is largely intentional, because while this demonstration has a simple list of words for a dictionary, in a larger language understanding system, "ran" and "run" have different temporal meanings. If they should be treated the same, the semantic analysis of the larger system should take care of this.

The system will always halt, but will retry different paths if a) backtracking is feasible (there are more possible interpretations) and b) the current guess isn't in the dictionary.

If analysis fails, but the word exists verbatim in the dictionary, the verbatim entry is the final guess. This way, "was" will remain "was" instead of being mangled to "wa" or similar.

Let's look at a few standard examples:

```text
don't -> do
don'tnonsense -> <impossible> (stopped at: don'tnonsense)
bashes -> bash
bathes -> bathe
leaning -> lean
lean -> lean
leaving -> leave
dented -> dent
danced -> dance
dogs -> dog
kisses -> kiss
curved -> curve
curled -> curl
rotting -> rot
rolling -> roll
patrolled -> patrol
played -> play
plied -> ply
realest -> real
palest -> pale
prettily -> pretty
ran -> ran
running -> run
run -> run
someone's -> someone
pleased -> please
robbed -> rob
```

Backtracking occurs on e.g. "patrolling" ("patroll" is rejected, same path that is valid for e.g. "roll(ing)").

Now a practical demonstration of why "technically correct" is sometimes still "kinda wrong":

```text
knives -> knive
nobly -> nob
```

You might have expected "knife" and "noble". However, 

- "knives" will become "knive", since "knive" is a valid word in our dictionary (a less common alt. to "knife")
- "nobly" will become "nob" (british slang for a noble person - very much not to be confused with "knob"). As such, "nobly" is the adverbial form (to "be like a nob") of "nob" rather than of "noble".

We can fix this by removing those weird words. This shows that this is not a bug in the analyser:

```moon
print "\n# Blacklist applied:"
tcc { "knives", "nobly" }, { "knive", "nob" }
```

yields

```text
knives -> knife
nobly -> noble
```