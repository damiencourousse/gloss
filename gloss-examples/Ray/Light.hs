{-# LANGUAGE BangPatterns #-}

module Light 
        ( Light(..)
        , applyLights
        , applyLight)
where
import Object
import Vec3


-- | A primitive light
data Light
        -- | A point light source, intensity drops off with distance from the point.
        = Light
        { lightPoint   :: Vec3
        , lightColor   :: Color }


-- | Compute the direct lighting at particular point for a list of lights.
applyLights
        :: [Object]     -- ^ Possible occluding objects, used for shadows.
        -> Vec3         -- ^ Point which is being lit.
        -> Vec3         -- ^ Surface normal at this point.
        -> [Light]      -- ^ Lights to consider.
        -> Color        -- ^ Total lighting at this point.


applyLights objs point normal lights
 = go lights (Vec3 0 0 0)
 where go [] total     = total
       go (light:rest) total
        = let !contrib = applyLight objs point normal light
          in  go rest (total + contrib)


-- | Compute the direct lighting at a particular point for a single light.
applyLight
        :: [Object]     -- possible occluding objects, used for shadows.
        -> Vec3         -- point which is being lit
        -> Vec3         -- surface normal at this point
        -> Light 
        -> Color

applyLight objs pt n (Light lpt color)
 = let
        -- vector from the light to the surface point
        !dir    = normaliseV3 (lpt - pt)

        -- distance from light source to surface
        !dist   = magnitudeV3 (lpt - pt)
        
        -- magnitude of reflection
        !mag    = (n `dotV3` dir) / (dist * dist)

        -- the light that is reflected
        !refl   = color `mulsV3` mag

        -- eliminate negative lights
        -- TODO: not sure if we ever to do this.
--      !final  = clampV3 refl 0.0 99999.0 
        !final  = refl


        -- check for occluding objects between the light and the surface point
        -- TODO: only need to know if something is infront, 
        --       not the actual distance.
   in   case castRay objs pt dir of
                Just (_, opt)
                 -> if magnitudeV3 (opt - pt) < dist
                        then Vec3 0.0 0.0 0.0
                        else final 
                        
                Nothing -> final
                 
