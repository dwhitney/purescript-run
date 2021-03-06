module Run.Except
  ( Except(..)
  , EXCEPT
  , FAIL
  , _except
  , liftExcept
  , runExcept
  , runFail
  , throw
  , fail
  , rethrow
  , note
  , fromJust
  , catch
  ) where

import Prelude

import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..), maybe')
import Run (Run, SProxy(..), FProxy)
import Run as Run

newtype Except e a = Except e

derive instance functorExcept ∷ Functor (Except e)

type EXCEPT e = FProxy (Except e)

type FAIL = EXCEPT Unit

_except ∷ SProxy "except"
_except = SProxy

liftExcept ∷ ∀ e a r. Except e a → Run (except ∷ EXCEPT e | r) a
liftExcept = Run.lift _except

throw ∷ ∀ e a r. e → Run (except ∷ EXCEPT e | r) a
throw = liftExcept <<< Except

fail ∷ ∀ a r. Run (except ∷ FAIL | r) a
fail = throw unit

rethrow ∷ ∀ e a r. Either e a → Run (except ∷ EXCEPT e | r) a
rethrow = either throw pure

note ∷ ∀ e a r. e → Maybe a → Run (except ∷ EXCEPT e | r) a
note e = maybe' (\_ → throw e) pure

fromJust ∷ ∀ a r. Maybe a → Run (except ∷ FAIL | r) a
fromJust = note unit

catch ∷ ∀ e a r. (e → Run r a) → Run (except ∷ EXCEPT e | r) a → Run r a
catch = loop
  where
  handle = Run.on _except Left Right
  loop k r = case Run.peel r of
    Left a → case handle a of
      Left (Except e) →
        k e
      Right a' →
        Run.send a' >>= catch k
    Right a →
      pure a

runExcept ∷ ∀ e a r. Run (except ∷ EXCEPT e | r) a → Run r (Either e a)
runExcept = loop
  where
  handle = Run.on _except Left Right
  loop r = case Run.peel r of
    Left a → case handle a of
      Left (Except e) →
        pure (Left e)
      Right a' →
        Run.send a' >>= runExcept
    Right a →
      pure (Right a)

runFail ∷ ∀ a r. Run (except ∷ FAIL | r) a → Run r (Maybe a)
runFail = map (either (const Nothing) Just) <<< runExcept
