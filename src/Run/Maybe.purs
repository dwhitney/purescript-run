module Run.Maybe where

import Prelude

import Data.Either (Either(..))
import Data.Functor.Variant (FProxy, SProxy(..))
import Data.Maybe (Maybe(..))
import Run (Run, lift, on, send)
import Run as Run

type MAYBE = FProxy Maybe

_maybe :: SProxy "maybe"
_maybe = SProxy

liftMaybe :: forall a r. Maybe a -> Run(maybe :: MAYBE | r) a
liftMaybe = lift _maybe 

runMaybe :: forall a r. Run (maybe :: MAYBE | r) a -> Run r (Maybe a)
runMaybe = loop
  where
  handle = on _maybe Left Right
  loop r = case Run.peel r of
    Left a -> case handle a of
      Left Nothing -> pure Nothing
      Left (Just b) -> loop b
      Right a' -> send a' >>= runMaybe
    Right a -> pure $ Just a
