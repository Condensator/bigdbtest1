CREATE TYPE [dbo].[ReceiptPostByFileErrorMessages] AS TABLE(
	[Code] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[ErrorMessage] [nvarchar](4000) COLLATE Latin1_General_CI_AS NULL
)
GO
