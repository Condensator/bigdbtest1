SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingCustomAmorts](
	[Id] [bigint] NOT NULL,
	[UploadCustomAmort] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomAmortDocument_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CustomAmortDocument_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CustomAmortDocument_Content] [varbinary](82) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingCustomAmorts]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingCustomAmort] FOREIGN KEY([Id])
REFERENCES [dbo].[DiscountingFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingCustomAmorts] CHECK CONSTRAINT [EDiscountingFinance_DiscountingCustomAmort]
GO
