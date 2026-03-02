-- Add job_closed_odo_img to driver_flow for end-of-job odometer photo URL (if missing).
-- Start odometer image is already stored in pdp_start_image.
ALTER TABLE public.driver_flow
  ADD COLUMN IF NOT EXISTS job_closed_odo_img text;

COMMENT ON COLUMN public.driver_flow.job_closed_odo_img IS 'URL of odometer photo when vehicle is returned (job end).';
