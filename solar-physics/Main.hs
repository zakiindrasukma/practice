{-# LANGUAGE ConstraintKinds, TemplateHaskell, QuasiQuotes #-}

import           Data.Metrology
import           Data.Metrology.SI
import           Data.Metrology.Show
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Text.Authoring
import Text.Authoring.TH
import Text.LaTeX (render)

import Astrophysics.Sun

paper :: MonadAuthoring s w m => m ()
paper = [inputQ|material/template.tex|]
  

main :: IO ()
main = do
  ((), st, latex) <- 
    runAuthoringT $ 
    withDatabaseFile "material/citation.db" paper
  bibTeX <- toBibliographyContent st
  T.writeFile "output/main.tex" $ render latex
  T.writeFile "output/the.bib" bibTeX
  
  