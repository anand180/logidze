CREATE OR REPLACE FUNCTION hstore_logger() RETURNS TRIGGER AS $body$
  DECLARE
    changes_h jsonb;
    size integer;
    buffer jsonb;
  BEGIN
    size := jsonb_array_length(NEW.log);
    
    changes_h := hstore_to_jsonb_loose(
      hstore(NEW.*) - hstore(OLD.*)
    );

    NEW.log := jsonb_set(
      NEW.log,
      ARRAY[size::text],
      jsonb_build_object(
        'ts',
        extract(epoch from now())::int,
        'i',
        (NEW.log#>>ARRAY[(size - 1)::text, 'i'])::int + 1,
        'd',
        changes_h
      ),
      true
    );
    return NEW;
  END;
  $body$
  LANGUAGE plpgsql;


ALTER TABLE pgbench_accounts ADD COLUMN log jsonb DEFAULT '[]' NOT NULL;

UPDATE pgbench_accounts SET log = to_jsonb(ARRAY[json_build_object('i', 0)])::jsonb;

CREATE TRIGGER hstore_log_accounts
BEFORE UPDATE ON pgbench_accounts FOR EACH ROW
EXECUTE PROCEDURE hstore_logger();
