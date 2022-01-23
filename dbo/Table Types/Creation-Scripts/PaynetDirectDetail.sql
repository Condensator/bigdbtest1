CREATE TYPE [dbo].[PaynetDirectDetail] AS TABLE(
	[RequestedDate] [datetimeoffset](7) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RequestedBy] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Source] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaynetCustomerName] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PaynetCustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DataRequestStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[DataReceivedDate] [date] NULL,
	[PaynetReport_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[PaynetReport_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PaynetReport_Content] [varbinary](82) NULL,
	[PaynetReportResponse] [varbinary](max) NULL,
	[PaynetLOSResponse] [varbinary](max) NULL,
	[PaynetLOSRequest] [varbinary](max) NULL,
	[PaynetReportRequest] [varbinary](max) NULL,
	[IsActive] [bit] NOT NULL,
	[IsFromWorkFlow] [bit] NOT NULL,
	[RequestedCompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[RequestedAlias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedAddress] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[RequestedCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedState] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[RequestedPhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[paynet_id] [bigint] NULL,
	[inquiries] [int] NULL,
	[master_score] [int] NULL,
	[master_score_key_factor_1] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[master_score_key_factor_2] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[master_score_key_factor_3] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[master_score_percentile] [int] NULL,
	[last_activity_reported_date] [date] NULL,
	[cur_bal_amt] [decimal](16, 2) NULL,
	[years_in_business] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[total_employees] [bigint] NULL,
	[past_due_3160_occurrences] [int] NULL,
	[past_due_6190_occurrences] [int] NULL,
	[past_due_91_plus_occurrences] [int] NULL,
	[past_due_31_plus_occurrences] [int] NULL,
	[cur_bal_cur_30_amt_Amount] [decimal](16, 2) NULL,
	[cur_bal_cur_30_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[cur_bal_past_due_3160_amt_Amount] [decimal](16, 2) NULL,
	[cur_bal_past_due_3160_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[cur_bal_past_due_6190_amt_Amount] [decimal](16, 2) NULL,
	[cur_bal_past_due_6190_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[cur_bal_past_due_91_plus_amt_Amount] [decimal](16, 2) NULL,
	[cur_bal_past_due_91_plus_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[cur_bal_past_due_31_plus_amt_Amount] [decimal](16, 2) NULL,
	[cur_bal_past_due_31_plus_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[past_due_3160_amt_Amount] [decimal](16, 2) NULL,
	[past_due_3160_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[past_due_6190_amt_Amount] [decimal](16, 2) NULL,
	[past_due_6190_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[past_due_91_plus_amt_Amount] [decimal](16, 2) NULL,
	[past_due_91_plus_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[past_due_31_plus_amt_Amount] [decimal](16, 2) NULL,
	[past_due_31_plus_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[cur_30_amt_pct_of_cur_bal] [decimal](5, 2) NULL,
	[past_due_3160_amt_pct_of_cur_bal] [decimal](5, 2) NULL,
	[past_due_6190_amt_pct_of_cur_bal] [decimal](5, 2) NULL,
	[past_due_91_plus_amt_pct_of_cur_bal] [decimal](5, 2) NULL,
	[past_due_31_plus_amt_pct_of_cur_bal] [decimal](5, 2) NULL,
	[orig_receivable_amt_Amount] [decimal](16, 2) NULL,
	[orig_receivable_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[high_credit_amt_Amount] [decimal](16, 2) NULL,
	[high_credit_amt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[cur_bal_amt_pct_of_orig_receivable] [decimal](5, 2) NULL,
	[cur_bal_amt_pct_of_high_credit] [decimal](5, 2) NULL,
	[most_recent_past_due_3160_date] [date] NULL,
	[most_recent_past_due_6190_date] [date] NULL,
	[most_recent_past_due_91_plus_date] [date] NULL,
	[CustomerId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
