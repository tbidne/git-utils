{-# LANGUAGE OverloadedStrings #-}

module CLI.FunctionalSpec
  ( spec,
  )
where

import App
import CLI.MonadCLI
import CLI.Parsing
import CLI.Types.Env
import qualified Control.Monad.Reader as R
import qualified Data.Text as T
import qualified System.IO as IO
import qualified System.IO.Silently as Shh
import qualified System.Process as P
import Test.Hspec

spec :: Spec
spec = afterAll_ tearDown $ beforeAll_ setup $ do
  describe "CLI.FunctionalSpec" $ do
    it "Should run commands" $ do
      env <- mkEnv
      output <- Shh.capture_ (runTest env)
      T.lines (T.pack output) `shouldSatisfy` allFound . foldMap sToVerifier

allFound :: Verifier -> Bool
allFound (Verifier True True True True True True) = True
allFound _ = False

sToVerifier :: T.Text -> Verifier
sToVerifier s
  -- verify expected commands
  | T.isInfixOf cmdEchoHi s = mempty {foundHi = True}
  | T.isInfixOf cmdEcho1 s = mempty {foundOne = True}
  | T.isInfixOf cmdEchoLong s = mempty {foundLong = True}
  | T.isInfixOf cmdBad s = mempty {foundBad = True}
  -- verify this occurs at least once
  | T.isInfixOf timeCmd s = mempty {foundTimeCmd = True}
  -- verify final counter
  | T.isInfixOf totalTime s = mempty {foundTotalTime = True}
  | otherwise = mempty

runTest :: Env -> IO ()
runTest env = R.runReaderT (runAppT runCLI) env

mkEnv :: IO Env
mkEnv = do
  let args =
        [ "--legend=./scripts/testing/cli/legend.txt",
          "--timeout=5",
          "bad",
          "both",
          "echo hi"
        ]
  res <- parseArgs args
  case res of
    Right env -> pure env
    Left e -> error ("Error parsing args: " <> show e)

setup :: IO ()
setup =
  let proc = (P.shell "./setup_legend.sh") {P.cwd = (Just "./scripts/testing/")}
   in Shh.hSilence [IO.stderr] $ P.readCreateProcess proc "" *> pure ()

tearDown :: IO ()
tearDown =
  let proc = (P.shell "./teardown_legend.sh") {P.cwd = (Just "./scripts/testing/")}
   in P.readCreateProcess proc "" *> pure ()

data Verifier
  = Verifier
      { foundHi :: Bool,
        foundOne :: Bool,
        foundLong :: Bool,
        foundBad :: Bool,
        foundTimeCmd :: Bool,
        foundTotalTime :: Bool
      }
  deriving (Show)

instance Semigroup Verifier where
  (Verifier a b c d e f) <> (Verifier a' b' c' d' e' f') =
    Verifier
      (a || a')
      (b || b')
      (c || c')
      (d || d')
      (e || e')
      (f || f')

instance Monoid Verifier where
  mempty = Verifier False False False False False False

cmdBad :: T.Text
cmdBad = errPrefix <> "Error running `some nonsense`"

cmdEchoHi :: T.Text
cmdEchoHi = infoSuccessPrefix <> "Successfully ran `echo hi`"

cmdEcho1 :: T.Text
cmdEcho1 = infoSuccessPrefix <> "Successfully ran `sleep 1 && echo 1`"

cmdEchoLong :: T.Text
cmdEchoLong = infoSuccessPrefix <> "Successfully ran `sleep 2 && echo long`"

timeCmd :: T.Text
timeCmd = infoSuccessPrefix <> "Time elapsed: "

totalTime :: T.Text
totalTime = infoBluePrefix <> "Total time elapsed: "

infoSuccessPrefix :: T.Text
infoSuccessPrefix = "\ESC[92m[Info] "

infoBluePrefix :: T.Text
infoBluePrefix = "\ESC[94m[Info] "

errPrefix :: T.Text
errPrefix = "\ESC[91m[Error] "
