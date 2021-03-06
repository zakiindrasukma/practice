{- Janken Game in operational.
   sample play session:

$ ./dist/build/test-02/test-02
> c
you lose
> c
draw
> ?
[(C,G),(C,C)]
> c?
you win
[(C,G),(C,C),(C,P)]
> pgc
you win
you win
you win
> ?
[(C,G),(C,C),(C,P),(P,G),(G,C),(C,P)]
> pqgc?
you win
you lose
you lose
you lose


-}


{-# LANGUAGE GADTs #-}

import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Operational
import Control.Monad.State
import Control.Monad.Trans.Loop
import System.IO
import System.Random

-- | Player's language
data PLang a where
    ReadLog :: PLang Log
    PlayHand  :: Hand -> PLang ()

type Player m a = ProgramT PLang m a
type Log = [(Hand, Hand)]
data Hand = G | C | P | S deriving (Eq, Ord, Read, Show)

versus :: Hand -> Hand -> String
versus S _ = "you lose"
versus _ S = "you win"
versus G C = "you win"
versus C P = "you win"
versus P G = "you win"
versus x y
  | x == y    = "draw"
  | otherwise = "you lose"

readLog :: ProgramT PLang m Log
readLog = singleton ReadLog

playHand :: Hand -> ProgramT PLang m ()
playHand = singleton . PlayHand

initialLog :: Log
initialLog = []

runGame :: MonadIO m => Player m () -> Player m () -> m ()
runGame player1 player2 = go initialLog player1 player2
  where
    go gameState p1 p2
      | length gameState >= 10 = return ()
      | otherwise = do
        (h1,kp1) <- getHand p1
        (h2,kp2) <- getHand p2
        liftIO $ putStrLn $ h1 `versus` h2
        go ((h1, h2) : gameState) (kp1 ()) (kp2 ())

        where
          getHand p = do
            vp <- viewT p
            case vp of
              Return _           -> return (S, \_ -> daiuchiPlayer)
              ReadLog :>>= kp  -> getHand (kp $ reverse gameState)
              PlayHand h :>>= kp -> return (h,kp)

main :: IO ()
main = runGame humanPlayer aiPlayer

humanPlayer :: MonadIO m => Player m ()
humanPlayer = while (return True) $ do
  str <- liftIO $ do
         putStr "> "
         hFlush stdout
         getLine
  mapM_ play str
    where
      play 'g' = lift $ playHand G -- play gu
      play 'c' = lift $ playHand C -- play peace
      play 'p' = lift $ playHand P -- play par
      play 's' = lift $ playHand S -- surrender this turn
      play '?' = lift $ do         -- see the log
        currentLog <- readLog
        liftIO $ print $ currentLog
      play 'q' = exit              -- abort game
      play _   = return ()

aiPlayer :: Monad m => Player m ()
aiPlayer = evalStateT ai $ cycle [G,C,P]
  where
    ai :: Monad m => StateT [Hand] (ProgramT PLang m) ()
    ai = forever $ do
      (h:t) <- get
      lift $ playHand h
      put t

daiuchiPlayer :: Monad m => Player m ()
daiuchiPlayer = forever $ playHand S