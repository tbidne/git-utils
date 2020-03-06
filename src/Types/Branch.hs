{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE GADTs             #-}
{-# LANGUAGE KindSignatures    #-}
{-# LANGUAGE OverloadedStrings #-}

module Types.Branch
  ( AnyBranch(..)
  , BranchStatus(..)
  , Branch(..)
  , mkAnyBranch
  )
where

import qualified Data.Text                     as T
import           Data.Time.Calendar             ( Day )

import           Types.GitTypes

data BranchStatus where
  Merged ::BranchStatus
  UnMerged ::BranchStatus

data Branch (a :: BranchStatus) where
  MkBranch ::Name -> Author -> Day -> Branch a

instance Show (Branch a) where
  show (MkBranch (Name n) _ _) =
    T.unpack $ case T.splitOn "origin/" (T.strip n) of
      [_, nm] -> nm
      _       -> "Err: " <> n

data AnyBranch where
  MergedBranch ::Branch 'Merged -> AnyBranch
  UnMergedBranch ::Branch 'UnMerged -> AnyBranch
  deriving Show

mkAnyBranch :: Name -> Author -> Day -> Bool -> AnyBranch
mkAnyBranch n a d b | b         = MergedBranch $ MkBranch n a d
                    | otherwise = UnMergedBranch $ MkBranch n a d
