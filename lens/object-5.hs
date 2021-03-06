{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE RankNTypes #-}
import           Control.Applicative hiding (empty)
import           Control.Lens
import           Data.Maybe
import qualified Data.Map as Map
import           Text.Printf

newtype Object = Object { unObject :: Map.Map String Double }
        deriving (Show)

member :: String -> Simple Traversal Object Double
member tag d2ad obj@(Object kvp) =
 case Map.lookup tag kvp of
   Just d -> (\d' -> Object $ Map.insert tag d' kvp) <$> (d2ad d)
   Nothing  -> pure obj

memberWithDefault :: String -> (Object -> Maybe Double) -> Simple Traversal Object Double
memberWithDefault tag defFunc d2ad obj@(Object kvp) =
  case Map.lookup tag kvp of
    Just d -> go d
    Nothing  -> case defFunc obj of
      Just d -> go d
      Nothing -> pure obj
  where
       go d = (\d' -> Object $ Map.insert tag d' kvp) <$> (d2ad d)


mass, velocity, momentum, energy ::  Simple Traversal Object Double
mass = member "mass"
velocity = memberWithDefault "velocity" $ \this -> do
  m <- this ^? mass
  mv <- this ^? momentum
  return (mv/m)

momentum = memberWithDefault "momentum" $ \this -> do
  m <- this ^? mass
  v <- this ^? velocity
  return (m*v)

energy = memberWithDefault "energy" $ \this -> do
  m <- this ^? mass
  v <- this ^? velocity
  return $ 0.5 * m * v * v


insert :: String -> Double -> Object -> Object
insert tag d (Object kvp) = Object $Map.insert tag d kvp

empty, hammer1, hammer2, laser :: Object
empty = Object Map.empty

-- mass and impact velocity is known for this hammer
hammer1 = empty & insert "mass" 30
                & insert "velocity" 40

-- mass and momentum is known for this hammer
hammer2 = empty & insert "mass" 50
                & insert "momentum" 1500

-- mass and velocity is not defined for laser
laser = empty & insert "energy" 26500

-- only mass is known for this object
deadweight = empty & insert "mass" 1e20


main = do
  print empty                  -- Object {unObject = fromList []}
  print hammer1                -- Object {unObject = fromList [("mass",30.0),("velocity",40.0)]}
  print $ hammer1 ^? velocity  -- Just 40.0
  print $ hammer1 ^? momentum  -- Just 1200.0
  print $ hammer2 ^? velocity  -- Just 30.0
  print $ hammer2 ^? momentum  -- Just 1500.0
  print $ empty ^? momentum    -- Nothing

  -- what is the most powerful tool for drilling?
  let energies = mapMaybe (^? energy) [empty,hammer1,hammer2,laser {- ,deadweight -}]
  print $ energies             -- [24000.0,22500.0,26500.0]
