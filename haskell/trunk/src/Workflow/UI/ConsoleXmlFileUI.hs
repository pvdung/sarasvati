{-
    This file is part of Sarasvati.

    Sarasvati is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    Sarasvati is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with Sarasvati.  If not, see <http://www.gnu.org/licenses/>.

    Copyright 2008 Paul Lorenz
-}

-- Author: Paul Lorenz

module Workflow.UI.ConsoleXmlFileUI where

import Workflow.Engine
import Workflow.Task.Task
import IO
import Data.Char
import System.Directory
import Workflow.Loaders.WorkflowLoadXml
import Workflow.Task.TaskXml
import qualified Data.Map as Map
import Workflow.UI.ConsoleCommon
import Workflow.MemoryWfEngine

consoleMain :: IO ()
consoleMain =
    do hSetBuffering stdout NoBuffering
       wfList <- getWorkflowList
       selectWorkflow wfList

selectWorkflow :: [String] -> IO ()
selectWorkflow wfList =
    do putStrLn "\n-=Available workflows=-"
       showWorkflows wfList 1
       putStr "\nSelect workflow: "
       wf <- getLine
       if ((not $ null wf) && all (isDigit) wf)
         then useWorkflow wfList (((read wf)::Int) - 1)
         else do putStrLn $ "ERROR: " ++ wf ++ " is not a valid workflow"
       selectWorkflow wfList

useWorkflow :: [String] -> Int -> IO ()
useWorkflow wfList idx
    | length wfList <= idx = do putStrLn "ERROR: Invalid workflow number"
    | otherwise            = do result <- loadWfGraphFromFile (wfList !! idx) elemFunctionMap
                                case (result) of
                                    Left msg -> putStrLn $ "ERROR: Could not load workflow: " ++ msg
                                    Right graph -> do putStrLn "Running workflow"
                                                      putStrLn (show graph)
                                                      runWorkflow graph
   where
       elemFunctionMap = elemMapWith [ ("task", processTaskElement) ]

runWorkflow :: WfGraph -> IO ()
runWorkflow graph =
    do engine <- newMemoryWfEngine
       result <- startWorkflow engine nodeTypeMap Map.empty graph []
       case (result) of
           Left msg -> putStrLn msg
           Right wf -> processTasks engine wf

nodeTypeMap :: Map.Map String (NodeType [Task])
nodeTypeMap = Map.fromList
                [ ( "start", NodeType evalGuardLang completeDefaultExecution ),
                  ( "node",  NodeType evalGuardLang completeDefaultExecution ),
                  ( "task",  NodeType evalGuardLang acceptAndCreateTask ) ]

getWorkflowList :: IO [String]
getWorkflowList =
    do fileList <- getDirectoryContents wfDir
       return $ (useFullPath.filterWfs) fileList
    where
        wfDir = "/home/paul/workspace/wf-haskell/common/test-wf/"
        filterWfs = (filter (hasExtension ".wf.xml"))
        useFullPath = (map (\f->wfDir ++ f))

hasExtension :: String -> String -> Bool
hasExtension ext name = all (\(x,y) -> x == y) $ zip (reverse ext) (reverse name)