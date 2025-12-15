-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Helper enums already exist from initial migration:
--   appointment_status, day_of_week, gender, op

-- ============================
-- Helper functions
-- ============================
CREATE OR REPLACE FUNCTION "DOW_FROM_DATE" ("date_" DATE) RETURNS "day_of_week" AS $$
DECLARE
    dow_ integer;
BEGIN
    dow_ := EXTRACT(dow FROM "date_");
    RETURN (
        CASE
            WHEN dow_ = 0 THEN 'sunday'
            WHEN dow_ = 1 THEN 'monday'
            WHEN dow_ = 2 THEN 'tuesday'
            WHEN dow_ = 3 THEN 'wednesday'
            WHEN dow_ = 4 THEN 'thursday'
            WHEN dow_ = 5 THEN 'friday'
            WHEN dow_ = 6 THEN 'saturday'
            ELSE 'monday'
        END
    );
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION "DOW_TO_NUM" ("dow_" "day_of_week") RETURNS INTEGER AS $$
    SELECT (
        CASE
            WHEN "dow_" = 'monday' THEN 1
            WHEN "dow_" = 'tuesday' THEN 2
            WHEN "dow_" = 'wednesday' THEN 3
            WHEN "dow_" = 'thursday' THEN 4
            WHEN "dow_" = 'friday' THEN 5
            WHEN "dow_" = 'saturday' THEN 6
            WHEN "dow_" = 'sunday' THEN 7
            ELSE 0
        END
    );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION "DOW_TO_DATE" (
    "day_" "day_of_week",
    "date_on_week" DATE DEFAULT CURRENT_DATE
) RETURNS DATE AS $$
DECLARE
    dow_ integer;
BEGIN
    dow_ := "DOW_TO_NUM"("day_");
    IF dow_ = 0 THEN
        dow_ := 7;
    END IF;
    RETURN "date_on_week" + MAKE_INTERVAL(days => (dow_ - EXTRACT(dow FROM "date_on_week"))::int);
END;
$$ LANGUAGE PLPGSQL;

-- ============================
-- Slot calculation views
-- ============================
CREATE OR REPLACE VIEW "TEMPLATE_SLOTS" AS (
    WITH RECURSIVE
        get_slot_start (
            "id_template",
            "start_time",
            "end_time",
            "slot_duration",
            "id_doctor",
            "day_of_week",
            "effective_from",
            "effective_to"
        ) AS (
            SELECT
                st."id_template",
                st."start_time",
                st."end_time",
                st."slot_duration",
                st."id_doctor",
                st."day_of_week",
                st."effective_from",
                st."effective_to"
            FROM "ScheduleTemplate" st
            UNION ALL
            SELECT
                "id_template",
                ("start_time" + ("slot_duration" * INTERVAL '1 minute'))::TIME(6) AS "start_time",
                "end_time",
                "slot_duration",
                "id_doctor",
                "day_of_week",
                "effective_from",
                "effective_to"
            FROM get_slot_start
            WHERE "start_time" < "end_time" - "slot_duration" * INTERVAL '1 minute'
        )
    SELECT
        "id_template",
        "id_doctor",
        "start_time",
        "end_time",
        "slot_duration",
        "day_of_week",
        "effective_from",
        "effective_to"
    FROM get_slot_start
    ORDER BY
        "id_doctor",
        "DOW_TO_NUM"("day_of_week"),
        "start_time"
);

CREATE OR REPLACE VIEW "SPECIFIC_SLOTS" AS (
    WITH RECURSIVE
        get_slot_start (
            "id_schedule",
            "start_time",
            "end_time",
            "slot_duration",
            "is_available",
            "id_doctor",
            "work_date"
        ) AS (
            SELECT
                s."id_schedule",
                s."start_time",
                s."end_time",
                s."slot_duration",
                s."is_available",
                s."id_doctor",
                s."work_date"
            FROM "Schedule" s
            WHERE s."is_available" = TRUE
            UNION ALL
            SELECT
                "id_schedule",
                ("start_time" + ("slot_duration" * INTERVAL '1 minute'))::TIME(6),
                "end_time",
                "slot_duration",
                "is_available",
                "id_doctor",
                "work_date"
            FROM get_slot_start
            WHERE "is_available" = TRUE
              AND "start_time" < "end_time" - "slot_duration" * INTERVAL '1 minute'
        )
    SELECT
        "id_schedule",
        "id_doctor",
        "start_time",
        "end_time",
        "slot_duration",
        "work_date"
    FROM get_slot_start
    ORDER BY
        "id_doctor",
        "work_date",
        "start_time"
);

-- ============================
-- Slot helper functions
-- ============================
CREATE OR REPLACE FUNCTION "DOCTOR_SLOTS_FOR_DATE" ("doctor_id" INTEGER, "date_" DATE) RETURNS TABLE (
    "work_date" DATE,
    "id_doctor" INTEGER,
    "start_time" TIME
) AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM "Schedule" s
        WHERE s."id_doctor" = "doctor_id" AND s."work_date" = "date_"
    )
    THEN
        RETURN QUERY (
            SELECT "date_", ds."id_doctor", ds."start_time"
            FROM (
                SELECT
                    ss."id_doctor",
                    ss."start_time",
                    ss."end_time",
                    LEAD(ss."start_time") OVER (ORDER BY ss."start_time") AS next_start_time
                FROM "SPECIFIC_SLOTS" ss
                WHERE ss."id_doctor" = "doctor_id" AND ss."work_date" = "date_"
            ) ds
            LEFT JOIN "Appointment" a
                ON ds."id_doctor" = a."id_doctor"
               AND a."appointment_time"::date = "date_"
               AND a."status" != 'cancelled'
               AND a."appointment_time"::time < COALESCE(ds.next_start_time, ds."end_time")
               AND (a."appointment_time" + a."duration" * INTERVAL '1 minute')::time > ds."start_time"
            WHERE a."id_doctor" IS NULL
            ORDER BY ds."start_time"
        );
    ELSE
        RETURN QUERY (
            SELECT "date_", ds."id_doctor", ds."start_time"
            FROM (
                SELECT
                    ts."id_doctor",
                    ts."start_time",
                    ts."end_time",
                    LEAD(ts."start_time") OVER (ORDER BY ts."start_time") AS next_start_time
                FROM "TEMPLATE_SLOTS" ts
                WHERE ts."id_doctor" = "doctor_id"
                  AND ts."day_of_week" = "DOW_FROM_DATE"("date_")
                  AND "date_" BETWEEN ts."effective_from" AND COALESCE(ts."effective_to", 'infinity')
            ) ds
            LEFT JOIN "Appointment" a
                ON ds."id_doctor" = a."id_doctor"
               AND a."appointment_time"::date = "date_"
               AND a."status" != 'cancelled'
               AND a."appointment_time"::time < COALESCE(ds.next_start_time, ds."end_time")
               AND (a."appointment_time" + a."duration" * INTERVAL '1 minute')::time > ds."start_time"
            WHERE a."id_doctor" IS NULL
            ORDER BY ds."start_time"
        );
    END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION "DOCTOR_SLOTS_FOR_PERIOD" (
    "doctor_id" INTEGER,
    "from_date" DATE,
    "period" INTERVAL
) RETURNS TABLE (
    "work_date" DATE,
    "id_doctor" INTEGER,
    "start_time" TIME
) AS $$
DECLARE
    cur_date DATE;
BEGIN
    FOR cur_date IN (
        SELECT generate_series::date AS cur_date
        FROM generate_series(
            "from_date",
            ("from_date" + "period" - INTERVAL '1 day')::date,
            INTERVAL '1 day'
        )
    )
    LOOP
        RETURN QUERY (
            SELECT cur_date, ds."id_doctor", ds."start_time"
            FROM "DOCTOR_SLOTS_FOR_DATE"("doctor_id", cur_date) ds
        );
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION "GET_WEEK_SCHEDULE" ("date_" DATE) RETURNS TABLE (
    "id_doctor" INTEGER,
    "work_date" DATE,
    "day_of_week" "day_of_week",
    "start_time" TIME,
    "end_time" TIME,
    "id_room" INTEGER,
    "slot_duration" INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        SELECT
            ts."id_doctor",
            "DOW_TO_DATE"(ts."day_of_week", "date_") AS work_date,
            ts."day_of_week",
            ts."start_time",
            ts."end_time",
            ts."id_room",
            ts."slot_duration"
        FROM "ScheduleTemplate" ts
        LEFT JOIN "Schedule" s
          ON ts."id_doctor" = s."id_doctor"
         AND "DOW_TO_DATE"(ts."day_of_week", "date_") = s."work_date"
        WHERE s."id_doctor" IS NULL
          AND "DOW_TO_DATE"(ts."day_of_week", "date_") BETWEEN ts."effective_from" AND COALESCE(ts."effective_to", 'infinity')
        UNION ALL
        SELECT
            s."id_doctor",
            s."work_date",
            "DOW_FROM_DATE"(s."work_date"),
            s."start_time",
            s."end_time",
            s."id_room",
            s."slot_duration"
        FROM "Schedule" s
        WHERE s."is_available" = TRUE
        ORDER BY "id_doctor", work_date, "start_time"
    );
END;
$$ LANGUAGE PLPGSQL;

-- ============================
-- Business views
-- ============================
CREATE OR REPLACE VIEW "V_DOCTOR_STATISTICS" AS
SELECT
    d."id_doctor",
    u."lname" || ' ' || u."name" || ' ' || COALESCE(u."mname", '') AS "doctor_full_name",
    d."license_number",
    d."experience_years",
    d."hire_date",
    COUNT(a."id_appointment") FILTER (WHERE a."id_appointment" IS NOT NULL) AS "total_appointments",
    COUNT(a."id_appointment") FILTER (WHERE a."status" = 'completed') AS "completed_appointments",
    COUNT(a."id_appointment") FILTER (WHERE a."status" = 'cancelled') AS "cancelled_appointments",
    COUNT(a."id_appointment") FILTER (WHERE a."status" = 'no_show') AS "no_show_appointments",
    COUNT(a."id_appointment") FILTER (WHERE a."status" = 'scheduled') AS "scheduled_appointments",
    COUNT(a."id_appointment") FILTER (
        WHERE a."id_appointment" IS NOT NULL
          AND a."appointment_time" >= CURRENT_DATE - INTERVAL '30 days'
    ) AS "appointments_last_30_days",
    COUNT(a."id_appointment") FILTER (
        WHERE a."status" = 'completed'
          AND a."appointment_time" >= CURRENT_DATE - INTERVAL '30 days'
    ) AS "completed_last_30_days",
    COUNT(a."id_appointment") FILTER (
        WHERE a."id_appointment" IS NOT NULL
          AND DATE_TRUNC('month', a."appointment_time"::DATE) = DATE_TRUNC('month', CURRENT_DATE)
    ) AS "appointments_current_month",
    COUNT(DISTINCT a."id_patient") AS "unique_patients",
    STRING_AGG(DISTINCT s."name", ', ' ORDER BY s."name") AS "specializations"
FROM "Doctor" d
JOIN "User" u ON d."id_user" = u."id_user"
LEFT JOIN "Appointment" a ON d."id_doctor" = a."id_doctor"
LEFT JOIN "DoctorSpecialization" ds ON d."id_doctor" = ds."id_doctor"
LEFT JOIN "Specialization" s ON ds."id_spec" = s."id_spec"
GROUP BY
    d."id_doctor",
    u."lname",
    u."name",
    u."mname",
    d."license_number",
    d."experience_years",
    d."hire_date";

COMMENT ON VIEW "V_DOCTOR_STATISTICS" IS 'Статистика по врачам: количество приемов, статусы, специализации';

CREATE OR REPLACE VIEW "V_DAILY_APPOINTMENTS" AS
SELECT
    a."id_appointment",
    a."appointment_time"::DATE AS "appointment_date",
    a."appointment_time"::TIME AS "appointment_time",
    a."status",
    a."duration",
    a."complaints",
    d."id_doctor",
    u_doctor."lname" || ' ' || u_doctor."name" || ' ' || COALESCE(u_doctor."mname", '') AS "doctor_full_name",
    STRING_AGG(DISTINCT s."name", ', ' ORDER BY s."name") AS "doctor_specializations",
    r."room_number",
    p."id_patient",
    u_patient."lname" || ' ' || u_patient."name" || ' ' || COALESCE(u_patient."mname", '') AS "patient_full_name",
    u_patient."birth_date",
    EXTRACT(YEAR FROM AGE(u_patient."birth_date")) AS "patient_age",
    uc."phone" AS "patient_phone",
    uc."email" AS "patient_email",
    STRING_AGG(
        DISTINCT COALESCE(dd."code" || ' - ', '') || pd."diagnosis_text",
        '; '
        ORDER BY COALESCE(dd."code" || ' - ', '') || pd."diagnosis_text"
    ) AS "diagnoses",
    COUNT(DISTINCT pr."id_prescription") AS "prescriptions_count",
    a."created_at",
    a."updated_at"
FROM "Appointment" a
JOIN "Doctor" d ON a."id_doctor" = d."id_doctor"
JOIN "User" u_doctor ON d."id_user" = u_doctor."id_user"
LEFT JOIN "DoctorSpecialization" ds ON d."id_doctor" = ds."id_doctor"
LEFT JOIN "Specialization" s ON ds."id_spec" = s."id_spec"
LEFT JOIN "Schedule" sch ON a."id_doctor" = sch."id_doctor" AND a."appointment_time"::DATE = sch."work_date"
LEFT JOIN "Room" r ON sch."id_room" = r."id_room"
JOIN "Patient" p ON a."id_patient" = p."id_patient"
JOIN "User" u_patient ON p."id_user" = u_patient."id_user"
LEFT JOIN "UserContact" uc ON u_patient."id_user" = uc."id_user" AND uc."is_primary" = TRUE
LEFT JOIN "PatientDiagnosis" pd ON a."id_appointment" = pd."id_appointment"
LEFT JOIN "DiagnosisDirectory" dd ON pd."id_diagnosis" = dd."id_diagnosis"
LEFT JOIN "Prescription" pr ON a."id_appointment" = pr."id_appointment"
GROUP BY
    a."id_appointment",
    a."appointment_time",
    a."status",
    a."duration",
    a."complaints",
    d."id_doctor",
    u_doctor."lname",
    u_doctor."name",
    u_doctor."mname",
    r."room_number",
    p."id_patient",
    u_patient."lname",
    u_patient."name",
    u_patient."mname",
    u_patient."birth_date",
    uc."phone",
    uc."email",
    a."created_at",
    a."updated_at";

COMMENT ON VIEW "V_DAILY_APPOINTMENTS" IS 'Детальный отчет по приемам с информацией о врачах, пациентах, диагнозах и назначениях';

-- ============================
-- Check constraints
-- ============================
ALTER TABLE "User" ADD CONSTRAINT "user_birth_date_check" CHECK ("birth_date" IS NULL OR "birth_date" <= CURRENT_DATE);

ALTER TABLE "UserContact" ADD CONSTRAINT "usercontact_contact_present_check" CHECK ("phone" IS NOT NULL OR "email" IS NOT NULL);
ALTER TABLE "UserContact" ADD CONSTRAINT "usercontact_email_check" CHECK ("email" IS NULL OR "email" ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
ALTER TABLE "UserContact" ADD CONSTRAINT "usercontact_phone_check" CHECK ("phone" IS NULL OR "phone" ~ '^\+?[1-9]\d{1,14}$');

ALTER TABLE "Passport" ADD CONSTRAINT "passport_series_check" CHECK ("series" > 0 AND "series" < 10000);
ALTER TABLE "Passport" ADD CONSTRAINT "passport_number_check" CHECK ("number" > 0 AND "number" <= 1000000);
ALTER TABLE "Passport" ADD CONSTRAINT "passport_issue_date_check" CHECK ("issue_date" IS NULL OR "issue_date" <= CURRENT_DATE);

ALTER TABLE "Doctor" ADD CONSTRAINT "doctor_experience_years_check" CHECK ("experience_years" >= 0);

ALTER TABLE "ScheduleTemplate" ADD CONSTRAINT "scheduletemplate_end_after_start_check" CHECK ("end_time" > "start_time");
ALTER TABLE "ScheduleTemplate" ADD CONSTRAINT "scheduletemplate_slot_duration_check" CHECK ("slot_duration" > 0);
ALTER TABLE "ScheduleTemplate" ADD CONSTRAINT "scheduletemplate_effective_to_check" CHECK ("effective_to" IS NULL OR "effective_to" >= "effective_from");

ALTER TABLE "Schedule" ADD CONSTRAINT "schedule_end_after_start_check" CHECK ("end_time" > "start_time");
ALTER TABLE "Schedule" ADD CONSTRAINT "schedule_slot_duration_check" CHECK ("slot_duration" > 0);

ALTER TABLE "Appointment" ADD CONSTRAINT "appointment_duration_check" CHECK ("duration" > 0);

ALTER TABLE "Prescription" ADD CONSTRAINT "prescription_medication_xor_check" CHECK (
    ("id_medication" IS NOT NULL AND "custom_medication_name" IS NULL)
    OR ("id_medication" IS NULL AND "custom_medication_name" IS NOT NULL)
);

-- ============================
-- Exclusion constraints
-- ============================
ALTER TABLE "ScheduleTemplate" ADD CONSTRAINT "scheduletemplate_doctor_day_ranges_excl"
    EXCLUDE USING GIST (
        "id_doctor" WITH =,
        "day_of_week" WITH =,
        daterange("effective_from", COALESCE("effective_to", 'infinity'::DATE), '[]') WITH &&,
        tsrange('2024-01-01'::TIMESTAMP + "start_time", '2024-01-01'::TIMESTAMP + "end_time", '[)') WITH &&
    );

ALTER TABLE "Schedule" ADD CONSTRAINT "schedule_doctor_work_date_tsrange_excl"
    EXCLUDE USING GIST (
        "id_doctor" WITH =,
        "work_date" WITH =,
        tsrange("work_date" + "start_time", "work_date" + "end_time", '[)') WITH &&
    ) WHERE ("is_available" = TRUE);

ALTER TABLE "Appointment" ADD CONSTRAINT "appointment_doctor_tsrange_excl"
    EXCLUDE USING GIST (
        "id_doctor" WITH =,
        tsrange("appointment_time", "appointment_time" + "duration" * INTERVAL '1 minute', '[)') WITH &&
    ) WHERE ("status" != 'cancelled');

-- ============================
-- Additional indexes
-- ============================
CREATE INDEX IF NOT EXISTS "appointment_doctor_date_idx" ON "Appointment"("id_doctor", ("appointment_time"::DATE));
CREATE UNIQUE INDEX IF NOT EXISTS "usercontact_one_primary_key" ON "UserContact"("id_user") WHERE "is_primary" = TRUE;
CREATE UNIQUE INDEX IF NOT EXISTS "patientdiagnosis_one_primary_key" ON "PatientDiagnosis"("id_appointment") WHERE "is_primary" = TRUE;

-- ============================
-- Comments
-- ============================
COMMENT ON TABLE "UserContact" IS 'Контактная информация (отдельно т.к. может быть несколько контактов)';
COMMENT ON TABLE "Patient" IS 'Пациенты';
COMMENT ON TABLE "Doctor" IS 'Врачи';
COMMENT ON TABLE "Specialization" IS 'Специализации врачей';
COMMENT ON TABLE "Room" IS 'Кабинеты';
COMMENT ON TABLE "Schedule" IS 'Кастомное расписание врача на конкретный день';
COMMENT ON TABLE "DiagnosisDirectory" IS 'Справочник диагнозов (МКБ-10)';
COMMENT ON TABLE "Medication" IS 'Справочник лекарств';

-- ============================
-- Triggers
-- ============================
CREATE OR REPLACE FUNCTION "ON_NEW_SCHEDULE_F" () RETURNS TRIGGER AS $$
BEGIN
    UPDATE "Appointment"
       SET "status" = 'cancelled'
     WHERE "appointment_time"::date = NEW."work_date"
       AND "id_doctor" = NEW."id_doctor"
       AND "status" = 'scheduled'
       AND (
            ("appointment_time"::time < NEW."start_time"
             AND ("appointment_time" + "duration" * INTERVAL '1 minute')::time > NEW."start_time")
            OR ("appointment_time"::time >= NEW."start_time"
                AND "appointment_time"::time < NEW."end_time")
            OR ("appointment_time"::time < NEW."start_time"
                AND ("appointment_time" + "duration" * INTERVAL '1 minute')::time > NEW."end_time")
       );
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER "ON_NEW_SCHEDULE_TR"
AFTER INSERT ON "Schedule"
FOR EACH ROW
EXECUTE FUNCTION "ON_NEW_SCHEDULE_F" ();

CREATE OR REPLACE FUNCTION "CLOSE_OPEN_ENDED_TEMPLATE_F" () RETURNS TRIGGER AS $$
BEGIN
    UPDATE "ScheduleTemplate" st
       SET "effective_to" = NEW."effective_from" - INTERVAL '1 day'
     WHERE st."id_doctor"   = NEW."id_doctor"
       AND st."day_of_week" = NEW."day_of_week"
       AND st."effective_to" IS NULL
       AND st."effective_from" <= NEW."effective_from";
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS "close_open_ended_template_tr" ON "ScheduleTemplate";
CREATE TRIGGER "close_open_ended_template_tr"
BEFORE INSERT ON "ScheduleTemplate"
FOR EACH ROW
EXECUTE FUNCTION "CLOSE_OPEN_ENDED_TEMPLATE_F" ();

CREATE OR REPLACE FUNCTION "UPDATE_UPDATED_AT_COLUMN" () RETURNS TRIGGER AS $$
BEGIN
    NEW."updated_at" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER "UPDATE_APPOINTMENT_UPDATED_AT"
BEFORE UPDATE ON "Appointment"
FOR EACH ROW
EXECUTE FUNCTION "UPDATE_UPDATED_AT_COLUMN" ();

-- Audit trigger function
CREATE OR REPLACE FUNCTION "AUDIT_DELTA_F" () RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
DECLARE
    col_name text;
    old_json jsonb := to_jsonb(OLD);
    new_json jsonb := to_jsonb(NEW);
    op_text  "op" := TG_OP;
    pk_json  jsonb := '{}'::jsonb;
BEGIN
    IF TG_TABLE_NAME = 'AUDIT_DELTA_HIST' THEN
        RETURN NULL;
    END IF;

    SELECT jsonb_object_agg(kcu.column_name, COALESCE(new_json, old_json)->kcu.column_name)
      INTO pk_json
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
       AND tc.table_schema    = kcu.table_schema
     WHERE tc.table_schema = TG_TABLE_SCHEMA
       AND tc.table_name   = TG_TABLE_NAME
       AND tc.constraint_type = 'PRIMARY KEY';

    pk_json := COALESCE(pk_json, '{}'::jsonb);

    FOR col_name IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = TG_TABLE_SCHEMA
          AND table_name   = TG_TABLE_NAME
    LOOP
        IF op_text = 'INSERT' THEN
            INSERT INTO "AUDIT_DELTA_HIST"("table_name", "pk_data", "column_name", "old_value", "new_value", "operation")
            VALUES (TG_TABLE_NAME, pk_json, col_name, NULL, new_json->>col_name, op_text);
        ELSIF op_text = 'DELETE' THEN
            INSERT INTO "AUDIT_DELTA_HIST"("table_name", "pk_data", "column_name", "old_value", "new_value", "operation")
            VALUES (TG_TABLE_NAME, pk_json, col_name, old_json->>col_name, NULL, op_text);
        ELSE
            IF (old_json->>col_name) IS DISTINCT FROM (new_json->>col_name) THEN
                INSERT INTO "AUDIT_DELTA_HIST"("table_name", "pk_data", "column_name", "old_value", "new_value", "operation")
                VALUES (TG_TABLE_NAME, pk_json, col_name, old_json->>col_name, new_json->>col_name, op_text);
            END IF;
        END IF;
    END LOOP;

    RETURN NULL;
END;
$$;

-- Audit triggers
CREATE OR REPLACE TRIGGER "USER_AUDIT_DELTA_F_TR"
AFTER INSERT OR UPDATE OR DELETE ON "User"
FOR EACH ROW
EXECUTE FUNCTION "AUDIT_DELTA_F" ();

CREATE OR REPLACE TRIGGER "USER_CONTACT_AUDIT_DELTA_F_TR"
AFTER INSERT OR UPDATE OR DELETE ON "UserContact"
FOR EACH ROW
EXECUTE FUNCTION "AUDIT_DELTA_F" ();

CREATE OR REPLACE TRIGGER "PASSPORT_AUDIT_DELTA_F_TR"
AFTER INSERT OR UPDATE OR DELETE ON "Passport"
FOR EACH ROW
EXECUTE FUNCTION "AUDIT_DELTA_F" ();

CREATE OR REPLACE TRIGGER "DOCTOR_AUDIT_DELTA_F_TR"
AFTER INSERT OR UPDATE OR DELETE ON "Doctor"
FOR EACH ROW
EXECUTE FUNCTION "AUDIT_DELTA_F" ();

CREATE OR REPLACE TRIGGER "PATIENT_AUDIT_DELTA_F_TR"
AFTER INSERT OR UPDATE OR DELETE ON "Patient"
FOR EACH ROW
EXECUTE FUNCTION "AUDIT_DELTA_F" ();

-- ============================
-- Procedures
-- ============================
CREATE OR REPLACE PROCEDURE "CLEAR_NO_SHOW" ("from_now" INTERVAL DEFAULT '12 months') LANGUAGE PLPGSQL AS $$
BEGIN
    DELETE FROM "Appointment"
    WHERE "status" = 'no_show' AND "created_at" < NOW() - "from_now";
END;
$$;

CREATE OR REPLACE PROCEDURE "NO_SHOW_OLD" ("from_now" INTERVAL DEFAULT '3 months') LANGUAGE PLPGSQL AS $$
BEGIN
    UPDATE "Appointment"
       SET "status" = 'no_show'
     WHERE "status" != 'no_show'
       AND "created_at" < NOW() - "from_now";
END;
$$;

CREATE OR REPLACE PROCEDURE "COMPLETE_APPOINTMENT" (
    "p_appointment_id" INTEGER,
    "p_diagnosis_text" TEXT,
    "p_diagnosis_code" TEXT DEFAULT NULL,
    "p_is_primary" BOOLEAN DEFAULT TRUE,
    "p_notes" TEXT DEFAULT NULL
) LANGUAGE PLPGSQL AS $$
DECLARE
    v_diagnosis_id INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "Appointment" WHERE "id_appointment" = "p_appointment_id") THEN
        RAISE EXCEPTION 'Запись с id % не найдена', "p_appointment_id";
    END IF;

    UPDATE "Appointment"
       SET "status" = 'completed',
           "updated_at" = CURRENT_TIMESTAMP
     WHERE "id_appointment" = "p_appointment_id";

    IF "p_diagnosis_code" IS NOT NULL THEN
        SELECT "id_diagnosis" INTO v_diagnosis_id
        FROM "DiagnosisDirectory"
        WHERE "code" = "p_diagnosis_code";

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Диагноз с кодом % не найден в справочнике', "p_diagnosis_code";
        END IF;
    END IF;

    INSERT INTO "PatientDiagnosis" (
        "id_appointment",
        "id_diagnosis",
        "diagnosis_text",
        "is_primary",
        "diagnosis_date",
        "notes"
    ) VALUES (
        "p_appointment_id",
        v_diagnosis_id,
        "p_diagnosis_text",
        "p_is_primary",
        CURRENT_DATE,
        "p_notes"
    );

    COMMIT;
END;
$$;

