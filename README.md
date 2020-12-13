# Letterboxed

Dictionary-based solver for NYTimes Letterboxed puzzle

---

Makes use of named capture groups to solve the Letterboxed puzzle with optimal word pairings and minimal repeats.

    return $D ? qr/
                        ^(?: (?&A)(?=(?&B)|(?&C)|(?&D)|$)
                           | (?&B)(?=(?&A)|(?&C)|(?&D)|$)
                           | (?&C)(?=(?&A)|(?&B)|(?&D)|$)
                           | (?&D)(?=(?&A)|(?&B)|(?&C)|$) )+$
                        (?(DEFINE)
                          (?<A> [$A] )
                          (?<B> [$B] )
                          (?<C> [$C] )
                          (?<D> [$D] ) )
                        /ix
               : $C ? qr/
                        ^(?: (?&A)(?=(?&B)|(?&C)|$)
                           | (?&B)(?=(?&A)|(?&C)|$)
                           | (?&C)(?=(?&A)|(?&B)|$) )+$
                        (?(DEFINE)
                          (?<A> [$A] )
                          (?<B> [$B] )
                          (?<C> [$C] ) )
                        /ix
               :      qr/
                        ^(?: (?&A)(?=(?&B))|$)
                           | (?&B)(?=(?&A))|$) )+$
                        (?(DEFINE)
                          (?<A> [$A] )
                          (?<B> [$B] ) )
                        /ix