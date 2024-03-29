module Compiler where

import Parser
import Lexer
import AttributeGrammar
import PrettyPrinter
import MFP
import ConstantPropagation
import LVAnalysis

import qualified Data.Map.Internal.Debug as MD
import qualified Data.Map as M
import qualified Data.Set as S

k :: Int
k = 2

compile :: String -> IO ()
compile source = do
  let program = happy $ alex source
  let synProgram  = wrap_Program  (sem_Program  program)  Inh_Program
  let program' = labelled_Syn_Program synProgram
  let synProgram' = wrap_Program' (sem_Program' program') Inh_Program'

  putStrLn ""
  putStrLn "# Program"
  putStrLn $ pretty_Syn_Program' synProgram'
  putStrLn $ printFlowList $ flow_Syn_Program' synProgram'
  putStrLn "Init"
  print (init_Syn_Program' synProgram')
  putStrLn "Final"
  print (final_Syn_Program' synProgram')
  putStrLn "Inter-flow"
  print (interflow_Syn_Program' synProgram')

  -- Set-up and show Live variable analysis
  putStrLn  "\n LV analysis"
  let flow = flow_Syn_Program' synProgram'
  let e = final_Syn_Program' synProgram'
  let i = init_Syn_Program' synProgram'
  let vars = vars_Syn_Program' synProgram'
  let interflow = interflow_Syn_Program' synProgram'
  let ibmap = labelBlockMapCollect_Syn_Program' synProgram'
  let params = procInOutCollect_Syn_Program' synProgram'
  let bottom = S.fromList $ vars_Syn_Program' synProgram'
  let lambdaF = lvLambda_Syn_Program' synProgram'
  let jotta = MkSet S.empty
  let lpmap = labelProcMapCollect_Syn_Program' synProgram'

  let lvResult = maximalFixedPoint (lvL jotta) (lvF flow) interflow k e jotta lambdaF 
  putStrLn $ showMFP (show . (\(MkSet x) -> x)) lvResult

  putStrLn "\n Constant Propagation"
  let testcp = constantPropagationAnalysis flow interflow k i vars ibmap lpmap params
  putStrLn $ showMFP (show . M.toList) testcp

