{-# LANGUAGE ScopedTypeVariables, NoMonomorphismRestriction, RecordWildCards #-}

module Main where

import           Control.Applicative
import qualified Data.HashMap.Lazy as HM
import           System.Directory
import           System.FilePath ((</>))
import           System.Log.Logger
-- 
import HEP.Automation.EventChain.Driver 
import HEP.Automation.EventChain.Type.MultiProcess
import HEP.Automation.EventChain.Type.Spec
import HEP.Automation.EventChain.Type.Process
import HEP.Automation.EventChain.SpecDSL
import HEP.Automation.MadGraph.Model.Axino
import HEP.Automation.MadGraph.SetupType
import HEP.Automation.MadGraph.Type
-- 
import qualified Paths_madgraph_auto as PMadGraph 
import qualified Paths_madgraph_auto_model as PModel 

jets = [1,2,3,4,-1,-2,-3,-4,21]

axino = [9000006]

neut = [1000022]

top :: [Int]
top = [6]

antitop :: [Int]
antitop = [-6]

bottom :: [Int]
bottom = [5]

antibottom :: [Int]
antibottom = [-5]

wplus :: [Int]
wplus = [24]

wminus :: [Int]
wminus = [-24]

p_neut :: DDecay
p_neut = d (neut, [t axino, t jets, t jets])

p_n1n1 :: DCross 
p_n1n1 = x (t proton, t proton, [t jets, t jets, p_neut, p_neut])

map_n1n1 :: ProcSpecMap
map_n1n1 = 
    HM.fromList [ (Nothing       , MGProc [] [ "p p > j j n1 n1 " ])
                , (Just (5,1000022,[]) , MGProc [] [ "n1 > ax j j  " ] ) 
		, (Just (6,1000022,[]) , MGProc [] [ "n1 > ax j j  " ] )
                ] 

proc :: SingleProc
proc = SingleProc "n1_decay" p_n1n1 map_n1n1 mgrunsetup

mgrunsetup :: NumOfEv -> SetNum -> RunSetup
mgrunsetup (NumOfEv nev) (SetNum sn) = 
  RS { numevent = nev
     , machine = LHC14 ATLAS
     , rgrun   = Auto
     , rgscale = 200.0
     , match   = NoMatch
     , cut     = NoCut 
     , pythia  = NoPYTHIA 
     , lhesanitizer = []
     , pgs     = NoPGS
     , uploadhep = NoUploadHEP
     , setnum  = sn
     }

getScriptSetup :: IO ScriptSetup
getScriptSetup = do 
  homedir <- getHomeDirectory
  mdldir <- (</> "template") <$> PModel.getDataDir
  rundir <- (</> "template") <$> PMadGraph.getDataDir 
  return $ 
    SS { modeltmpldir = mdldir 
       , runtmpldir = rundir 
       , sandboxdir = homedir </> "temp/montecarlo/sandbox"
       , mg5base    = homedir </> "temp/montecarlo/MG5_aMC_v2_1_0"
       , mcrundir   = homedir </> "temp/montecarlo/mcrun"
       , pythia8dir = ""
       , pythia8toHEPEVT = "" 
       , hepevt2stdhep = "" 
       }

pdir :: ProcDir
pdir = ProcDir { pdWorkDirPrefix = "Axino_2jetsquark" 
               , pdRemoteDirBase = "Axino_2jetsquark"
               , pdRemoteDirPrefix = "Axino_2jetsquark" }


 
main :: IO () 
main = do 
  updateGlobalLogger "MadGraphAuto" (setLevel DEBUG)
  ssetup <- getScriptSetup
  genPhase1 Axino ssetup pdir proc AxinoParam (NumOfEv 10000,SetNum 1)
  genPhase2 Axino ssetup pdir proc AxinoParam (NumOfEv 10000,SetNum 1)

