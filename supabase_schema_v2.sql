-- v2 升級：讓每個 Team 可以分開填 start / end，並新增備註欄位。
-- 如果你已經建過 public.project_tasks，直接執行本檔案即可。
-- 如果是第一次建表，也可以執行本檔案，會自動補齊需要欄位。

CREATE TABLE IF NOT EXISTS public.project_tasks (
  id text PRIMARY KEY,
  seq integer NOT NULL DEFAULT 0,
  item text NOT NULL DEFAULT '',
  is_section boolean NOT NULL DEFAULT false,
  pm_fae boolean NOT NULL DEFAULT false,
  owner_system boolean NOT NULL DEFAULT false,
  owner_data boolean NOT NULL DEFAULT false,
  owner_model boolean NOT NULL DEFAULT false,
  start_date date,
  end_date date,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.project_tasks
  ADD COLUMN IF NOT EXISTS pm_fae_start_date date,
  ADD COLUMN IF NOT EXISTS pm_fae_end_date date,
  ADD COLUMN IF NOT EXISTS system_start_date date,
  ADD COLUMN IF NOT EXISTS system_end_date date,
  ADD COLUMN IF NOT EXISTS data_start_date date,
  ADD COLUMN IF NOT EXISTS data_end_date date,
  ADD COLUMN IF NOT EXISTS model_start_date date,
  ADD COLUMN IF NOT EXISTS model_end_date date,
  ADD COLUMN IF NOT EXISTS notes text NOT NULL DEFAULT '';

-- 將舊版 start/end 自動帶到有負責的 Team 日期欄，避免舊資料升級後變空白。
UPDATE public.project_tasks
SET
  pm_fae_start_date = COALESCE(pm_fae_start_date, CASE WHEN pm_fae THEN start_date END),
  pm_fae_end_date   = COALESCE(pm_fae_end_date,   CASE WHEN pm_fae THEN end_date END),
  system_start_date = COALESCE(system_start_date, CASE WHEN owner_system THEN start_date END),
  system_end_date   = COALESCE(system_end_date,   CASE WHEN owner_system THEN end_date END),
  data_start_date   = COALESCE(data_start_date,   CASE WHEN owner_data THEN start_date END),
  data_end_date     = COALESCE(data_end_date,     CASE WHEN owner_data THEN end_date END),
  model_start_date  = COALESCE(model_start_date,  CASE WHEN owner_model THEN start_date END),
  model_end_date    = COALESCE(model_end_date,    CASE WHEN owner_model THEN end_date END)
WHERE start_date IS NOT NULL OR end_date IS NOT NULL;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_project_tasks_updated_at ON public.project_tasks;
CREATE TRIGGER trg_project_tasks_updated_at
BEFORE UPDATE ON public.project_tasks
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "project_tasks_select_all" ON public.project_tasks;
DROP POLICY IF EXISTS "project_tasks_insert_all" ON public.project_tasks;
DROP POLICY IF EXISTS "project_tasks_update_all" ON public.project_tasks;
DROP POLICY IF EXISTS "project_tasks_delete_all" ON public.project_tasks;

CREATE POLICY "project_tasks_select_all"
ON public.project_tasks FOR SELECT
USING (true);

CREATE POLICY "project_tasks_insert_all"
ON public.project_tasks FOR INSERT
WITH CHECK (true);

CREATE POLICY "project_tasks_update_all"
ON public.project_tasks FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "project_tasks_delete_all"
ON public.project_tasks FOR DELETE
USING (true);

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.project_tasks TO anon, authenticated;

-- 若已加入 publication，這行可能會提示已存在，可忽略。
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.project_tasks;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;
