{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverlappingInstances #-}
{-# LANGUAGE UndecidableInstances #-}

class Copyable v a b | v a -> b where
  copy :: v a -> v b

class Reduce v a w b| v a -> w b where
  reduce :: v a -> w b

instance Reduce Maybe a [] a where
  reduce (Just x) = [x]
  reduce Nothing  = []

instance Copyable [] Char () where
  copy x = [()]

instance (Copyable w b (), Reduce v a w b) => Reduce v a w () where
  reduce = copy . reduce

main = do
  print "hi"
--  print $ reduce $ Just 'i' 

{-
$ runhaskell  copy-05.hs

c.f. chapter 7.6.3.3 of http://www.haskell.org/ghc/docs/7.6.1/html/users_guide/type-class-extensions.html

    Context reduction stack overflow; size = 201
    Use -fcontext-stack=N to increase stack size to N
      Copyable w b ()
    In the second argument of `(.)', namely `reduce'
    In the expression: copy . reduce
    In an equation for `reduce': reduce = copy . reduce

-}