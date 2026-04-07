Table "cs"."addresses" {
  "id" integer [pk, not null]
  "customer_id_number" "character varying(50)" [not null]
  "municipality_code" "character varying(10)" [not null]
  "street" "character varying(255)" [not null]
  "detail" "character varying(255)"
  "postal_code" "character varying(20)"
  "additional_comments" "character varying(100)"
  "created_at" timestamp [default: `CURRENT_TIMESTAMP`]
  "updated_at" timestamp [default: `CURRENT_TIMESTAMP`]
}

Table "cs"."customers" {
  "id" integer [pk, not null]
  "id_number" "character varying(50)" [unique, not null]
  "birth_date" date [not null]
  "phone_number" "character varying(20)" [not null]
  "name" "character varying(255)" [not null]
  "email" "character varying(255)" [unique, not null]
  "created_at" timestamp [default: `CURRENT_TIMESTAMP`]

  Checks {
    `(birth_date < CURRENT_DATE)` [name: 'chk_birth_date']
  }
}

Table "pay"."orders" {
  "id" "character varying(25)" [pk, not null]
  "customer_id_number" "character varying(50)" [not null]
  "order_date" timestamp [default: `CURRENT_TIMESTAMP`]
  "total" numeric(10,2)
  "payment_method_id" integer [not null]
}

Table "pay"."order_items" {
  "id" integer [pk, not null]
  "order_id" "character varying(25)" [not null]
  "product_id" integer [not null]
  "quantity" integer [not null]

  Checks {
    `(quantity > 0)` [name: 'chk_quantity']
  }
}

Table "ctg"."products" {
  "id" integer [pk, not null]
  "name" "character varying(255)" [not null]
  "usd_price" numeric(10,2) [not null]
  "cop_price" numeric(10,2)
  "category_id" integer
}

Table "ctg"."categories" {
  "id" integer [pk, not null]
  "name" "character varying(50)" [unique, not null]
  "created_at" timestamp [default: `CURRENT_TIMESTAMP`]
}

Table "ctg"."departments" {
  "code" "character varying(10)" [pk, not null]
  "name" "character varying(100)" [not null]
}

Table "ctg"."municipalities" {
  "code" "character varying(10)" [pk, not null]
  "name" "character varying(100)" [not null]
  "department_code" "character varying(10)" [not null]
}

Table "ctg"."payment_methods" {
  "id" integer [pk, not null]
  "name" "character varying(50)" [unique, not null]
  "create_at" timestamp [default: `CURRENT_TIMESTAMP`]
}

Table "ship"."ship_company" {
  "id" integer [pk, not null]
  "name" "character varying(100)" [unique, not null]
  "nit" "character varying(20)" [unique]
  "address" "character varying(100)" [not null]
  "phone" "character varying(20)"
  "email" "character varying(100)"
  "created_at" timestamp [default: `CURRENT_TIMESTAMP`]
}

Table "ship"."shipment_orders" {
  "id" "character varying(25)" [pk, not null]
  "ship_company_id" integer [not null]
  "order_id" "character varying(25)" [not null]
  "tracking_code" "character varying(100)" [unique]
  "status" "character varying(20)" [not null, default: `'pending'::charactervarying`]
  "shipped_at" timestamp
  "delivered_at" timestamp
  "created_at" timestamp [default: `CURRENT_TIMESTAMP`]
  "updated_at" timestamp [default: `CURRENT_TIMESTAMP`]

  Checks {
    `((status)::text = ANY ((ARRAY['pending'::character varying, 'in_transit'::character varying, 'delivered'::character varying])::text[]))` [name: 'chk_shipment_status']
  }
}

Ref "fk_addr_customer":"cs"."customers"."id_number" < "cs"."addresses"."customer_id_number"

Ref "fk_addr_municipality":"ctg"."municipalities"."code" < "cs"."addresses"."municipality_code"

Ref "fk_categories_id":"ctg"."categories"."id" < "ctg"."products"."category_id"

Ref "fk_department_code":"ctg"."departments"."code" < "ctg"."municipalities"."department_code"

Ref "fk_order_orders":"pay"."orders"."id" < "pay"."order_items"."order_id"

Ref "fk_order_products":"ctg"."products"."id" < "pay"."order_items"."product_id"

Ref "fk_orders_customer":"cs"."customers"."id_number" < "pay"."orders"."customer_id_number"

Ref "fk_payments_method":"ctg"."payment_methods"."id" < "pay"."orders"."payment_method_id"

Ref "fk_order_shipments":"pay"."orders"."id" < "ship"."shipment_orders"."order_id"

Ref "fk_shipment_company":"ship"."ship_company"."id" < "ship"."shipment_orders"."ship_company_id"
