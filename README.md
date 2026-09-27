# jev-field-notes

Code and results from one evening testing Jev, a System One classification model from TypeSafe AI.

Jev reads text and answers questions you define in advance (yes/no, pick from a list, or a score), returning one answer with a probability. This lab asks it whether each of four made-up movie reviews recommends the movie.

## Results

| Movie Review | Probability the writer recommends the movie |
|---|---|
| "I went in with low expectations but the ending had me on the edge of my seat. I would watch it again." | 0.94 |
| "The acting was fine but the plot dragged and I checked my phone twice." | 0.13 |
| "Worst two hours of my year. Do not bother." | 0.01 |
| "My brother loved it. I thought it was boring." | 0.08 |

One call with four questions: 408 input tokens, $0.000017 list price, 115 ms inside the model, 547 ms round trip from Ohio.

## How to run it

1. Create a Vercel account and an AI Gateway API key. The gateway requires a card on file.
2. Store the key in your environment. Never put it in a file in this repo.

```
   export AI_GATEWAY_API_KEY="your-key"
```

3. Run the script:

```
   bash batch.sh
```

Use made-up data only. Every request goes to Vercel's gateway and TypeSafe's servers.

## Write-ups

- Part I, for executives: https://pavankristipati.substack.com/p/one-evening-with-jev-part-i-what
- Part II, the lab: https://pavankristipati.substack.com/p/one-evening-with-jev-part-ii-the

## Notes

Built with AI assistance. Released under the MIT License.
