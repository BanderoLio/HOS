-- CreateEnum
CREATE TYPE "appointment_status" AS ENUM ('scheduled', 'completed', 'cancelled', 'no_show');

-- CreateEnum
CREATE TYPE "day_of_week" AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

-- CreateEnum
CREATE TYPE "gender" AS ENUM ('m', 'w');

-- CreateEnum
CREATE TYPE "op" AS ENUM ('INSERT', 'UPDATE', 'DELETE');

-- CreateTable
CREATE TABLE "Appointment" (
    "id_appointment" SERIAL NOT NULL,
    "id_patient" INTEGER NOT NULL,
    "id_doctor" INTEGER NOT NULL,
    "appointment_time" TIMESTAMP(6) NOT NULL,
    "duration" INTEGER DEFAULT 15,
    "status" "appointment_status" DEFAULT 'scheduled',
    "complaints" TEXT,
    "created_at" TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Appointment_pkey" PRIMARY KEY ("id_appointment")
);

-- CreateTable
CREATE TABLE "AUDIT_DELTA_HIST" (
    "audit_id" BIGSERIAL NOT NULL,
    "table_name" TEXT NOT NULL,
    "pk_data" JSONB NOT NULL,
    "column_name" TEXT NOT NULL,
    "old_value" TEXT,
    "new_value" TEXT,
    "operation" "op" NOT NULL,
    "changed_at" TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AUDIT_DELTA_HIST_pkey" PRIMARY KEY ("audit_id")
);

-- CreateTable
CREATE TABLE "Doctor" (
    "id_doctor" SERIAL NOT NULL,
    "id_user" INTEGER NOT NULL,
    "license_number" TEXT NOT NULL,
    "experience_years" INTEGER,
    "hire_date" DATE DEFAULT CURRENT_DATE,

    CONSTRAINT "Doctor_pkey" PRIMARY KEY ("id_doctor")
);

-- CreateTable
CREATE TABLE "Specialization" (
    "id_spec" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,

    CONSTRAINT "Specialization_pkey" PRIMARY KEY ("id_spec")
);

-- CreateTable
CREATE TABLE "DoctorSpecialization" (
    "id_doctor" INTEGER NOT NULL,
    "id_spec" INTEGER NOT NULL,
    "assigned_date" DATE DEFAULT CURRENT_DATE,

    CONSTRAINT "DoctorSpecialization_pkey" PRIMARY KEY ("id_doctor","id_spec")
);

-- CreateTable
CREATE TABLE "DiagnosisDirectory" (
    "id_diagnosis" SERIAL NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,

    CONSTRAINT "DiagnosisDirectory_pkey" PRIMARY KEY ("id_diagnosis")
);

-- CreateTable
CREATE TABLE "PatientDiagnosis" (
    "id_patient_diagnosis" SERIAL NOT NULL,
    "id_appointment" INTEGER NOT NULL,
    "id_diagnosis" INTEGER,
    "diagnosis_text" TEXT NOT NULL,
    "is_primary" BOOLEAN DEFAULT true,
    "diagnosis_date" DATE DEFAULT CURRENT_DATE,
    "notes" TEXT,

    CONSTRAINT "PatientDiagnosis_pkey" PRIMARY KEY ("id_patient_diagnosis")
);

-- CreateTable
CREATE TABLE "Medication" (
    "id_medication" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "active_substance" TEXT,
    "form" TEXT,
    "dosage" TEXT,

    CONSTRAINT "Medication_pkey" PRIMARY KEY ("id_medication")
);

-- CreateTable
CREATE TABLE "Prescription" (
    "id_prescription" SERIAL NOT NULL,
    "id_appointment" INTEGER NOT NULL,
    "id_medication" INTEGER,
    "custom_medication_name" TEXT,
    "dosage" TEXT NOT NULL,
    "frequency" TEXT NOT NULL,
    "duration" TEXT,
    "instructions" TEXT,
    "prescription_date" DATE DEFAULT CURRENT_DATE,
    "is_issued" BOOLEAN DEFAULT false,

    CONSTRAINT "Prescription_pkey" PRIMARY KEY ("id_prescription")
);

-- CreateTable
CREATE TABLE "Patient" (
    "id_patient" SERIAL NOT NULL,
    "id_user" INTEGER NOT NULL,
    "id_passport" INTEGER,
    "id_address" INTEGER,
    "insurance_policy" TEXT,
    "registration_date" DATE DEFAULT CURRENT_DATE,

    CONSTRAINT "Patient_pkey" PRIMARY KEY ("id_patient")
);

-- CreateTable
CREATE TABLE "Room" (
    "id_room" SERIAL NOT NULL,
    "room_number" TEXT NOT NULL,
    "floor" INTEGER,
    "description" TEXT,

    CONSTRAINT "Room_pkey" PRIMARY KEY ("id_room")
);

-- CreateTable
CREATE TABLE "Schedule" (
    "id_schedule" SERIAL NOT NULL,
    "id_doctor" INTEGER NOT NULL,
    "work_date" DATE NOT NULL,
    "start_time" TIME(6) NOT NULL,
    "end_time" TIME(6) NOT NULL,
    "id_room" INTEGER,
    "slot_duration" INTEGER NOT NULL DEFAULT 15,
    "is_available" BOOLEAN DEFAULT true,
    "notes" TEXT,

    CONSTRAINT "Schedule_pkey" PRIMARY KEY ("id_schedule")
);

-- CreateTable
CREATE TABLE "ScheduleTemplate" (
    "id_template" SERIAL NOT NULL,
    "id_doctor" INTEGER NOT NULL,
    "day_of_week" "day_of_week" NOT NULL,
    "start_time" TIME(6) NOT NULL,
    "end_time" TIME(6) NOT NULL,
    "id_room" INTEGER,
    "slot_duration" INTEGER NOT NULL DEFAULT 15,
    "effective_from" DATE NOT NULL DEFAULT CURRENT_DATE,
    "effective_to" DATE,

    CONSTRAINT "ScheduleTemplate_pkey" PRIMARY KEY ("id_template")
);

-- CreateTable
CREATE TABLE "User" (
    "id_user" SERIAL NOT NULL,
    "lname" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "mname" TEXT,
    "gender" "gender",
    "birth_date" DATE,
    "created_at" TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id_user")
);

-- CreateTable
CREATE TABLE "Account" (
    "id_account" TEXT NOT NULL,
    "id_user" INTEGER,
    "username" TEXT NOT NULL,
    "password" TEXT,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id_account")
);

-- CreateTable
CREATE TABLE "Role" (
    "id_role" SERIAL NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "Role_pkey" PRIMARY KEY ("id_role")
);

-- CreateTable
CREATE TABLE "UserContact" (
    "id_contact" SERIAL NOT NULL,
    "id_user" INTEGER NOT NULL,
    "phone" TEXT,
    "email" TEXT,
    "is_primary" BOOLEAN DEFAULT false,

    CONSTRAINT "UserContact_pkey" PRIMARY KEY ("id_contact")
);

-- CreateTable
CREATE TABLE "Passport" (
    "id_passport" SERIAL NOT NULL,
    "series" INTEGER NOT NULL,
    "number" INTEGER NOT NULL,
    "issued_by" TEXT,
    "issue_date" DATE,

    CONSTRAINT "Passport_pkey" PRIMARY KEY ("id_passport")
);

-- CreateTable
CREATE TABLE "Address" (
    "id_address" SERIAL NOT NULL,
    "country" TEXT DEFAULT 'Россия',
    "region" TEXT,
    "city" TEXT NOT NULL,
    "street" TEXT,
    "house" TEXT,
    "apartment" TEXT,
    "postal_code" TEXT,

    CONSTRAINT "Address_pkey" PRIMARY KEY ("id_address")
);

-- CreateTable
CREATE TABLE "_AccountToRole" (
    "A" TEXT NOT NULL,
    "B" INTEGER NOT NULL,

    CONSTRAINT "_AccountToRole_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE INDEX "appointment_id_doctor_fkey" ON "Appointment"("id_doctor");

-- CreateIndex
CREATE INDEX "appointment_id_patient_fkey" ON "Appointment"("id_patient");

-- CreateIndex
CREATE INDEX "appointment_status_idx" ON "Appointment"("status");

-- CreateIndex
CREATE INDEX "appointment_time_idx" ON "Appointment"("appointment_time");

-- CreateIndex
CREATE INDEX "AUDIT_DELTA_HIST_changed_at_idx" ON "AUDIT_DELTA_HIST"("changed_at");

-- CreateIndex
CREATE INDEX "AUDIT_DELTA_HIST_operation_idx" ON "AUDIT_DELTA_HIST"("operation");

-- CreateIndex
CREATE INDEX "AUDIT_DELTA_HIST_pk_data_idx" ON "AUDIT_DELTA_HIST" USING GIN ("pk_data");

-- CreateIndex
CREATE INDEX "audit_delta_hist_table_changed_idx" ON "AUDIT_DELTA_HIST"("table_name", "changed_at");

-- CreateIndex
CREATE INDEX "AUDIT_DELTA_HIST_table_name_idx" ON "AUDIT_DELTA_HIST"("table_name");

-- CreateIndex
CREATE UNIQUE INDEX "Doctor_id_user_key" ON "Doctor"("id_user");

-- CreateIndex
CREATE UNIQUE INDEX "Doctor_license_number_key" ON "Doctor"("license_number");

-- CreateIndex
CREATE INDEX "doctor_id_user_fkey" ON "Doctor"("id_user");

-- CreateIndex
CREATE UNIQUE INDEX "Specialization_name_key" ON "Specialization"("name");

-- CreateIndex
CREATE UNIQUE INDEX "DiagnosisDirectory_code_key" ON "DiagnosisDirectory"("code");

-- CreateIndex
CREATE INDEX "patientdiagnosis_id_appointment_fkey" ON "PatientDiagnosis"("id_appointment");

-- CreateIndex
CREATE UNIQUE INDEX "Medication_name_key" ON "Medication"("name");

-- CreateIndex
CREATE INDEX "prescription_id_appointment_fkey" ON "Prescription"("id_appointment");

-- CreateIndex
CREATE UNIQUE INDEX "Patient_id_user_key" ON "Patient"("id_user");

-- CreateIndex
CREATE UNIQUE INDEX "Patient_id_passport_key" ON "Patient"("id_passport");

-- CreateIndex
CREATE UNIQUE INDEX "Patient_insurance_policy_key" ON "Patient"("insurance_policy");

-- CreateIndex
CREATE INDEX "patient_id_user_fkey" ON "Patient"("id_user");

-- CreateIndex
CREATE UNIQUE INDEX "Room_room_number_key" ON "Room"("room_number");

-- CreateIndex
CREATE INDEX "schedule_doctor_date_idx" ON "Schedule"("id_doctor", "work_date");

-- CreateIndex
CREATE INDEX "schedule_id_doctor_fkey" ON "Schedule"("id_doctor");

-- CreateIndex
CREATE INDEX "schedule_work_date_idx" ON "Schedule"("work_date");

-- CreateIndex
CREATE UNIQUE INDEX "Schedule_id_doctor_work_date_start_time_key" ON "Schedule"("id_doctor", "work_date", "start_time");

-- CreateIndex
CREATE INDEX "scheduletemplate_id_doctor_fkey" ON "ScheduleTemplate"("id_doctor");

-- CreateIndex
CREATE UNIQUE INDEX "ScheduleTemplate_id_doctor_day_of_week_start_time_effective_key" ON "ScheduleTemplate"("id_doctor", "day_of_week", "start_time", "effective_from");

-- CreateIndex
CREATE UNIQUE INDEX "Account_id_user_key" ON "Account"("id_user");

-- CreateIndex
CREATE UNIQUE INDEX "Account_username_key" ON "Account"("username");

-- CreateIndex
CREATE UNIQUE INDEX "Role_name_key" ON "Role"("name");

-- CreateIndex
CREATE INDEX "usercontact_id_user_fkey" ON "UserContact"("id_user");

-- CreateIndex
CREATE UNIQUE INDEX "UserContact_id_user_email_key" ON "UserContact"("id_user", "email");

-- CreateIndex
CREATE UNIQUE INDEX "UserContact_id_user_phone_key" ON "UserContact"("id_user", "phone");

-- CreateIndex
CREATE UNIQUE INDEX "Passport_series_number_key" ON "Passport"("series", "number");

-- CreateIndex
CREATE INDEX "_AccountToRole_B_index" ON "_AccountToRole"("B");

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_id_doctor_fkey" FOREIGN KEY ("id_doctor") REFERENCES "Doctor"("id_doctor") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_id_patient_fkey" FOREIGN KEY ("id_patient") REFERENCES "Patient"("id_patient") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Doctor" ADD CONSTRAINT "Doctor_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "User"("id_user") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "DoctorSpecialization" ADD CONSTRAINT "DoctorSpecialization_id_doctor_fkey" FOREIGN KEY ("id_doctor") REFERENCES "Doctor"("id_doctor") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "DoctorSpecialization" ADD CONSTRAINT "DoctorSpecialization_id_spec_fkey" FOREIGN KEY ("id_spec") REFERENCES "Specialization"("id_spec") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "PatientDiagnosis" ADD CONSTRAINT "PatientDiagnosis_id_appointment_fkey" FOREIGN KEY ("id_appointment") REFERENCES "Appointment"("id_appointment") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "PatientDiagnosis" ADD CONSTRAINT "PatientDiagnosis_id_diagnosis_fkey" FOREIGN KEY ("id_diagnosis") REFERENCES "DiagnosisDirectory"("id_diagnosis") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Prescription" ADD CONSTRAINT "Prescription_id_appointment_fkey" FOREIGN KEY ("id_appointment") REFERENCES "Appointment"("id_appointment") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Prescription" ADD CONSTRAINT "Prescription_id_medication_fkey" FOREIGN KEY ("id_medication") REFERENCES "Medication"("id_medication") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Patient" ADD CONSTRAINT "Patient_id_address_fkey" FOREIGN KEY ("id_address") REFERENCES "Address"("id_address") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Patient" ADD CONSTRAINT "Patient_id_passport_fkey" FOREIGN KEY ("id_passport") REFERENCES "Passport"("id_passport") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Patient" ADD CONSTRAINT "Patient_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "User"("id_user") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Schedule" ADD CONSTRAINT "Schedule_id_doctor_fkey" FOREIGN KEY ("id_doctor") REFERENCES "Doctor"("id_doctor") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Schedule" ADD CONSTRAINT "Schedule_id_room_fkey" FOREIGN KEY ("id_room") REFERENCES "Room"("id_room") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ScheduleTemplate" ADD CONSTRAINT "ScheduleTemplate_id_doctor_fkey" FOREIGN KEY ("id_doctor") REFERENCES "Doctor"("id_doctor") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ScheduleTemplate" ADD CONSTRAINT "ScheduleTemplate_id_room_fkey" FOREIGN KEY ("id_room") REFERENCES "Room"("id_room") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "User"("id_user") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "UserContact" ADD CONSTRAINT "UserContact_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "User"("id_user") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "_AccountToRole" ADD CONSTRAINT "_AccountToRole_A_fkey" FOREIGN KEY ("A") REFERENCES "Account"("id_account") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_AccountToRole" ADD CONSTRAINT "_AccountToRole_B_fkey" FOREIGN KEY ("B") REFERENCES "Role"("id_role") ON DELETE CASCADE ON UPDATE CASCADE;
