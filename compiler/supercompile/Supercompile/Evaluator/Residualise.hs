module Supercompile.Evaluator.Residualise (residualiseState, residualiseHeapBinding, pPrintHeap, pPrintFullState, pPrintFullUnnormalisedState) where

import Supercompile.Evaluator.Deeds
import Supercompile.Evaluator.Syntax

import Supercompile.Core.FreeVars
import Supercompile.Core.Renaming
import Supercompile.Core.Syntax

import Supercompile.Utilities

import Data.Either
import qualified Data.Map as M


residualiseState :: State -> (Deeds, Out [(Var, PrettyFunction)], Out FVedTerm)
residualiseState s = (deeds, floats_static, bindManyMixedLiftedness fvedTermFreeVars floats_nonstatic e)
 where (deeds, floats_static, floats_nonstatic, e) = residualiseUnnormalisedState (denormalise s)

residualiseUnnormalisedState :: UnnormalisedState -> (Deeds, Out [(Var, PrettyFunction)], Out [(Var, FVedTerm)], Out FVedTerm)
residualiseUnnormalisedState (deeds, heap, k, in_e) = (deeds, floats_static, floats_nonstatic, e)
  where (floats_static, floats_nonstatic, e) = residualiseHeap heap (\ids -> residualiseStack ids k (residualiseTerm ids in_e))

residualiseAnswer :: InScopeSet -> Answer -> Out FVedTerm
residualiseAnswer ids = fvedTerm . detagAnnedTerm' . answerToAnnedTerm' ids

residualiseTerm :: InScopeSet -> In AnnedTerm -> Out FVedTerm
residualiseTerm ids = detagAnnedTerm . renameIn (renameAnnedTerm ids)

residualiseHeap :: Heap -> (InScopeSet -> ((Out [(Var, PrettyFunction)], Out [(Var, FVedTerm)]), Out FVedTerm)) -> (Out [(Var, PrettyFunction)], Out [(Var, FVedTerm)], Out FVedTerm)
residualiseHeap (Heap h ids) resid_body = (floats_static_h ++ floats_static_k, floats_nonstatic_h ++ floats_nonstatic_k, e)
  where (floats_static_h, floats_nonstatic_h) = residualisePureHeap ids h
        ((floats_static_k, floats_nonstatic_k), e) = resid_body ids

residualisePureHeap :: InScopeSet -> PureHeap -> (Out [(Var, PrettyFunction)], Out [(Var, FVedTerm)])
residualisePureHeap ids h = partitionEithers [fmapEither ((,) x') ((,) x') (residualiseHeapBinding ids hb) | (x', hb) <- M.toList h]

residualiseHeapBinding :: InScopeSet -> HeapBinding -> Either (Out PrettyFunction) (Out FVedTerm)
residualiseHeapBinding ids (HB InternallyBound (Right in_e)) = Right (residualiseTerm ids in_e)
residualiseHeapBinding _   hb                                = Left (asPrettyFunction hb)

residualiseStack :: InScopeSet -> Stack -> Out FVedTerm -> ((Out [(Var, PrettyFunction)], Out [(Var, FVedTerm)]), Out FVedTerm)
residualiseStack _   []     e_body = (([], []), e_body)
residualiseStack ids (kf:k) e_body = first ((static_floats ++) *** (nonstatic_floats ++)) $ residualiseStack ids k e
  where ((static_floats, nonstatic_floats), e) = residualiseStackFrame ids (tagee kf) e_body

residualiseStackFrame :: InScopeSet -> StackFrame -> Out FVedTerm -> ((Out [(Var, PrettyFunction)], Out [(Var, FVedTerm)]), Out FVedTerm)
residualiseStackFrame _   (TyApply ty')               e  = (([], []), e `tyApp` ty')
residualiseStackFrame _   (CoApply co')               e  = (([], []), e `coApp` co')
residualiseStackFrame _   (Apply x2')                 e1 = (([], []), e1 `app` x2')
residualiseStackFrame ids (Scrutinise x' ty in_alts)  e  = (([], []), case_ e x' ty (detagAnnedAlts $ renameIn (renameAnnedAlts ids) in_alts))
residualiseStackFrame ids (PrimApply pop tys' as es') e  = (([], []), primOp pop tys' (map (residualiseAnswer ids . annee) as ++ e : map (residualiseTerm ids) es'))
residualiseStackFrame ids (StrictLet x' in_e2)        e1 = (([], []), let_ x' e1 (residualiseTerm ids in_e2))
residualiseStackFrame _   (Update x')                 e  = (([], [(x', e)]), var x')
residualiseStackFrame _   (CastIt co')                e  = (([], []), e `cast` co')


pPrintHeap :: Heap -> SDoc
pPrintHeap (Heap h ids) = pPrint $ map (first (PrettyDoc . pPrintBndr LetBind)) $ floats_static_h ++ [(x, asPrettyFunction1 e) | (x, e) <- floats_nonstatic_h]
  where (floats_static_h, floats_nonstatic_h) = residualisePureHeap ids h

pPrintFullState :: Bool -> State -> SDoc
pPrintFullState include_statics = pPrintFullUnnormalisedState include_statics . denormalise

pPrintFullUnnormalisedState :: Bool -> UnnormalisedState -> SDoc
pPrintFullUnnormalisedState include_statics state = text "Deeds:" <+> pPrint deeds $$ (if include_statics then pPrint (map (first (PrettyDoc . pPrintBndr LetBind)) floats_static) else empty) $$ body
  where (deeds, floats_static, floats_nonstatic, e) = residualiseUnnormalisedState state
        body = pPrintPrecLetRec noPrec floats_nonstatic (PrettyDoc (angleBrackets (pPrint e)))
