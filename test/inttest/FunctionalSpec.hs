{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ViewPatterns #-}

module FunctionalSpec where

import App
import qualified Control.Monad.Reader as R
import Core.MonadStaleBranches
import qualified Data.Time.Calendar as Cal
import qualified Data.Time.Clock as Clock
import Parsing.Core
import qualified System.IO as IO
import qualified System.IO.Silently as Shh
import qualified System.Process as P
import Test.Hspec
import Types.Env

spec :: Spec
spec = afterAll_ tearDown $ beforeAll_ setup $ do
  describe "IO Functional tests with real git repo" $ do
    it "Should have 0 Errors, 20 Merged, and 14 Unmerged" $ do
      env <- mkEnv
      output <- Shh.capture_ (runTest env)
      lines output `shouldSatisfy` verifyOutput

runTest :: Env -> IO ()
runTest env = R.runReaderT (runAppT runGitUtils) env

mkEnv :: IO Env
mkEnv = do
  d <- currDay
  let args =
        [ "--grep=1",
          "--path=./scripts/testing/test-git",
          "--branchType=local",
          "--master=master",
          "--limit=0"
        ]
  case parseArgs d args of
    Right env -> return env
    Left e -> error ("Error parsing args: " <> show e)

setup :: IO ()
setup =
  let proc = (P.shell "./setup_git_repo.sh") {P.cwd = (Just "./scripts/testing/")}
   in Shh.hSilence [IO.stderr] $ P.readCreateProcess proc "" *> pure ()

tearDown :: IO ()
tearDown =
  let proc = (P.shell "./teardown.sh") {P.cwd = (Just "./scripts/testing/")}
   in P.readCreateProcess proc "" *> pure ()

currDay :: IO Cal.Day
currDay = fmap Clock.utctDay Clock.getCurrentTime

startsWith :: Eq a => [a] -> [a] -> Maybe [a]
startsWith [] ys = Just ys
startsWith _ [] = Nothing
startsWith (x : xs) (y : ys)
  | x == y = startsWith xs ys
  | otherwise = Nothing

verifyOutput :: [String] -> Bool
verifyOutput = allTrue . toVerifier

newtype Verifier = Verifier (Bool, Bool, Bool)

instance Semigroup Verifier where
  (Verifier (x, y, z)) <> (Verifier (x', y', z')) = Verifier ((x || x'), (y || y'), (z || z'))

instance Monoid Verifier where
  mempty = Verifier (False, False, False)

allTrue :: Verifier -> Bool
allTrue (Verifier (True, True, True)) = True
allTrue _ = False

toVerifier :: [String] -> Verifier
toVerifier = foldr ((<>) . f) mempty
  where
    f (startsWith "ERRORS: " -> Just res) = Verifier ((res == "0"), False, False)
    f (startsWith "MERGED: " -> Just res) = Verifier (False, (res == "20"), False)
    f (startsWith "UNMERGED: " -> Just res) = Verifier (False, False, (res == "14"))
    f _ = mempty